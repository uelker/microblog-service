terraform {
  backend "s3" {
    bucket = "microblog-service-infrastructure-state"
    key    = "shared/terraform.tfstate"
    region = "eu-central-1"
  }
}
