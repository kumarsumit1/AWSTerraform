#For base version and TF state file
terraform {
  required_version = "0.12.20"
  required_providers {
    aws = "> 3.0"
  }
  #   backend "s3" {  }
  backend "local" {}
}


#For region
provider "aws" {
  region = var.aws_region
}


# For getting user_details
data "aws_caller_identity" "current" {}

# Remote State management 
# data "terraform_remote_state" "remote_state" {
#   backend = "s3"

#   config = {
#     bucket = "${var.remote_state_bucket}"
#     dynamodb_table = "${var.remote_state_table}"
#     key    = "${var.remote_state_key}"
#     region = "${var.aws_region}"
#   }
# }
