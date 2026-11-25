terraform {
  required_version = "~> 1.14.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "= 6.74.0" }
  }

}
provider "aws" {
  region              = var.home_region
  allowed_account_ids = [var.account_id]
  default_tags { tags = { Project = "aws-cloud-hardening-baseline", Version = "3" } }
}
