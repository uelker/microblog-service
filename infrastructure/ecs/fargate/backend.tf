terraform {
  backend "s3" {
    bucket = "microblog-service-infrastructure-state"
    key    = "ecs/fargate/terraform.tfstate"
    region = "eu-central-1"
  }
}
