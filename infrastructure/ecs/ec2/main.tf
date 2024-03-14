# Network

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "microblog-ec2-vpc"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public_subnets" {
  count                   = var.public_subnet_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 1)
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "microblog-ec2-public-subnet-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "microblog-ec2-igw"
  }
}

resource "aws_route_table" "second" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "microblog-ec2-public-rt"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table_association" "public_subnet" {
  count          = var.public_subnet_count
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
  route_table_id = aws_route_table.second.id
}

# Application Load Balancer

resource "aws_security_group" "alb" {
  description = "Allow HTTP traffic to Application Load Balancer"
  name        = "microblog-ec2-alb-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "microblog-ec2-alb-sg"
  }
}

resource "aws_alb" "ecs_alb" {
  name            = "microblog-ec2-alb"
  security_groups = [aws_security_group.alb.id]
  subnets         = aws_subnet.public_subnets[*].id
}

resource "aws_alb_listener" "microblog" {
  load_balancer_arn = aws_alb.ecs_alb.arn
  port              = 80

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.microblog.id
  }

  tags = {
    Name = "microblog-ec2-alb-listener"
  }
}

resource "aws_alb_target_group" "microblog" {
  name        = "microblog-ec2-alb-tg"
  vpc_id      = aws_vpc.main.id
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"

  health_check {
    path = "/microblog-service/healthcheck"
  }
}

# Auto Scaling Group

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_instance" {
  name               = "microblog-ec2-instance-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

data "aws_iam_policy" "ec2_instance_role" {
  name = "AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ec2_instance_role_attach" {
  role       = aws_iam_role.ec2_instance.name
  policy_arn = data.aws_iam_policy.ec2_instance_role.arn
}

resource "aws_iam_instance_profile" "ec2_instance" {
  name = "microblog-ec2-instance-profile"
  role = aws_iam_role.ec2_instance.name
}

resource "aws_security_group" "asg" {
  name        = "microblog-ec2-asg-sg"
  description = "Security group for EC2 instances in ECS cluster"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow ingress traffic from ALB on HTTP"
    from_port       = 32768
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow all egress traffic"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "microblog-ec2-asg-sg"
  }
}

data "aws_ami" "amazon_linux_ecs_optimized_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-ecs-hvm-2023.*-x86_64"]
  }
}


resource "aws_launch_template" "ecs" {
  name                   = "microblog-ecs-launch-template"
  image_id               = data.aws_ami.amazon_linux_ecs_optimized_2023.id
  instance_type          = var.ec2_instance_type
  vpc_security_group_ids = [aws_security_group.asg.id]

  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2_instance.arn
  }

  user_data = base64encode(templatefile("ecs.tftpl", {
    ecs_cluster_name = aws_ecs_cluster.microblog_service.name
  }))
}

resource "aws_autoscaling_group" "ecs" {
  name                  = "microblog-ecs-asg"
  vpc_zone_identifier   = aws_subnet.public_subnets[*].id
  desired_capacity      = 0
  min_size              = 0
  max_size              = var.asg_max_size
  protect_from_scale_in = true

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }
}

# ECS Cluster

resource "aws_ecs_cluster" "microblog_service" {
  name = "microblog-ec2-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_capacity_provider" "ecs_cap" {
  name = "microblog-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs.arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      maximum_scaling_step_size = 1000
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "ecs_caps" {
  cluster_name       = aws_ecs_cluster.microblog_service.name
  capacity_providers = [aws_ecs_capacity_provider.ecs_cap.name]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.ecs_cap.name
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "microblog-ec2-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "microblog-ec2-task-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy" "ecs_task_execution_role" {
  name = "AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy" "dynamodb_full_access" {
  name = "AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = data.aws_iam_policy.ecs_task_execution_role.arn
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_attach" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = data.aws_iam_policy.dynamodb_full_access.arn
}

resource "aws_cloudwatch_log_group" "microblog" {
  name              = "/aws/ecs/microblog-service/ec2"
  retention_in_days = 30
}

data "aws_region" "current" {}

resource "aws_ecs_task_definition" "microblog_service" {
  family             = "microblog-service-ec2"
  network_mode       = "bridge"
  task_role_arn      = aws_iam_role.ecs_task_role.arn
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "microblog-service-ec2"
      image     = var.image_url
      cpu       = var.task_cpu
      memory    = var.task_memory
      essential = true

      portMappings = [
        {
          containerPort = 8080
          hostPort      = 0
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options   = {
          "awslogs-group"         = aws_cloudwatch_log_group.microblog.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "task"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "microblog" {
  name            = "microblog-service-ec2"
  cluster         = aws_ecs_cluster.microblog_service.id
  task_definition = aws_ecs_task_definition.microblog_service.arn
  desired_count   = 2

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_cap.name
    weight            = 1
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.microblog.arn
    container_name   = "microblog-service-ec2"
    container_port   = 8080
  }
}


resource "aws_appautoscaling_target" "microblog_service" {
  max_capacity       = 10
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.microblog_service.name}/${aws_ecs_service.microblog.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "microblog_service_cpu" {
  name               = "microblog-ec2-scaling-cpu-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.microblog_service.resource_id
  scalable_dimension = aws_appautoscaling_target.microblog_service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.microblog_service.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 50
    scale_in_cooldown  = 120
    scale_out_cooldown = 120
  }
}

resource "aws_appautoscaling_policy" "microblog_service_memory" {
  name               = "microblog-ec2-scaling-memory-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.microblog_service.resource_id
  scalable_dimension = aws_appautoscaling_target.microblog_service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.microblog_service.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = 50
    scale_in_cooldown  = 120
    scale_out_cooldown = 120
  }
}
