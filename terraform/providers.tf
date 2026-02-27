terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.5.0"
}

provider "aws" {
  region = "ap-southeast-1"

  default_tags {
    tags = {
      Environment = "Dev"
      Project     = "Hybrid-Cloud-DevOps"
      ManagedBy   = "Terraform"
    }
  }
}