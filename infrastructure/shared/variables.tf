variable "dynamodb_table_name" {
  description = "The name of the DynamoDB table"
  type        = string
  default     = "Posts"
}

variable "ecr_repository_name" {
  description = "The name of the ECR repository"
  type        = string
  default     = "microblog-service"
}
