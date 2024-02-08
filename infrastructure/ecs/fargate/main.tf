# Network

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "microblog-fargate-vpc"
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
    Name = "microblog-fargate-public-subnet-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "microblog-fargate-igw"
  }
}

resource "aws_route_table" "second" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "microblog-fargate-public-rt"
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
  name        = "microblog-fargate-alb-sg"
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
    Name = "microblog-fargate-alb-sg"
  }
}

resource "aws_alb" "ecs_alb" {
  name            = "microblog-fargate-alb"
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
    Name = "microblog-fargate-alb-listener"
  }
}

resource "aws_alb_target_group" "microblog" {
  name        = "microblog-fargate-alb-tg"
  vpc_id      = aws_vpc.main.id
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"

  health_check {
    path = "/microblog-service/healthcheck"
  }
}

# ECS Cluster

resource "aws_ecs_cluster" "microblog_service" {
  name = "microblog-fargate-cluster"
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
  name               = "microblog-fargate-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "microblog-fargate-task-role"
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

resource "aws_security_group" "task_sg" {
  name        = "microblog-fargate-task-sg"
  description = "Security group for Fargate Service in ECS cluster"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow ingress traffic from ALB on HTTP"
    from_port       = 8080
    to_port         = 8080
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
    Name = "microblog-fargate-task-sg"
  }
}

resource "aws_cloudwatch_log_group" "microblog" {
  name              = "/aws/ecs/microblog-service/fargate"
  retention_in_days = var.service_log_retention
}

## ECS Task Definition and Service

data "aws_region" "current" {}

resource "aws_ecs_task_definition" "microblog" {
  family                   = "microblog-service-fargate"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = var.task_cpu
  memory                   = var.task_memory

  container_definitions = jsonencode([
    {
      name      = "microblog-service-fargate"
      image     = var.image_url
      cpu       = var.task_cpu
      memory    = var.task_memory
      essential = true

      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
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
  name            = "microblog-service"
  cluster         = aws_ecs_cluster.microblog_service.id
  task_definition = aws_ecs_task_definition.microblog.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.public_subnets.*.id
    security_groups  = [aws_security_group.task_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.microblog.arn
    container_name   = "microblog-service-fargate"
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
  name               = "microblog-fargate-scaling-cpu-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.microblog_service.resource_id
  scalable_dimension = aws_appautoscaling_target.microblog_service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.microblog_service.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 50
  }
}

resource "aws_appautoscaling_policy" "microblog_service_memory" {
  name               = "microblog-fargate-scaling-memory-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.microblog_service.resource_id
  scalable_dimension = aws_appautoscaling_target.microblog_service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.microblog_service.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = 50
  }
}
