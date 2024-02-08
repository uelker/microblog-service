terraform {
  backend "s3" {
    bucket = "microblog-service-infrastructure-state"
    key    = "ecs/ec2/terraform.tfstate"
    region = "eu-central-1"
  }
}

