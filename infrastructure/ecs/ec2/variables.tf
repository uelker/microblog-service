variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_count" {
  description = "The number of public subnets"
  type        = number
  default     = 3
}

variable "ec2_instance_type" {
  description = "Tbe instance type of the ec2 instances in asg"
  type        = string
  default     = "t2.micro"
}

variable "asg_max_size" {
  description = "The maximum size of the ec2 autoscaling group"
  type        = number
  default     = 5
}

variable "service_log_retention" {
  description = "The log retention period for the microblog-service"
  type        = number
  default     = 7
}

variable "image_url" {
  description = "The URL of the microblog-service image"
  type        = string
}

variable "task_cpu" {
  description = "The number of CPU units for the microblog-service"
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "The amount of memory for the microblog-service"
  type        = number
  default     = 256
}
