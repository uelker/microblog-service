#  Role and policies for lambda function to write logs and access database

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "microblog-service-lambda-container-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy" "lambda_basic_execution" {
  name = "AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy" "dynamodb_full_access" {
  name = "AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy_attachment" "policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  for_each   = toset([data.aws_iam_policy.lambda_basic_execution.arn, data.aws_iam_policy.dynamodb_full_access.arn])
  policy_arn = each.key
}

# Lambda function to run the microblog-service

resource "aws_lambda_function" "microblog_service" {
  function_name = "microblog-service-container"
  image_uri     = var.image_url
  package_type  = "Image"
  role          = aws_iam_role.lambda_role.arn
  timeout       = 30
  memory_size   = var.function_memory
}

# Lambda function url to access the microblog-service

resource "aws_lambda_function_url" "microblog_service" {
  function_name      = aws_lambda_function.microblog_service.function_name
  authorization_type = "NONE"
}
