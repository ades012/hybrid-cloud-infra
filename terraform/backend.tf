terraform {
  backend "s3" {
    bucket         = "ades012-hybrid-cloud-tfstate"
    key            = "hybrid-cloud/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}