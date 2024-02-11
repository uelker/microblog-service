resource "aws_dynamodb_table" "posts" {
  name         = var.dynamodb_table_name
  hash_key     = "id"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_ecr_repository" "microblog-service" {
  name = var.ecr_repository_name
}
