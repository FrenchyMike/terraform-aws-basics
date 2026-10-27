provider "aws" {
    region = var.AWS_REGION
    access_key = var.AWS_ACCESS_KEY
    secret_key = var.AWS_SECRET_KEY
}

provider "tls" {}

provider "local" {}

provider "external" {}

terraform {
  backend "s3" {
    bucket = "terraform-mike-devops"
    key    = "states/terraform.tfstate"
    region = "eu-west-3"
  }
}
