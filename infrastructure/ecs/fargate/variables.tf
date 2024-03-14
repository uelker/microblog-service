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
  default     = 1024
}
