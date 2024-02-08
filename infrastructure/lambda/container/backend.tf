terraform {
  backend "s3" {
    bucket = "microblog-service-infrastructure-state"
    key    = "lambda/container/terraform.tfstate"
    region = "eu-central-1"
  }
}
