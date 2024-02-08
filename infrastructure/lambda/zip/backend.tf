terraform {
  backend "s3" {
    bucket = "microblog-service-infrastructure-state"
    key    = "lambda/zip/terraform.tfstate"
    region = "eu-central-1"
  }
}
