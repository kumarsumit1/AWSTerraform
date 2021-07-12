
variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "my_bucket" {
  description = "Test bucket name"
  default = "mybucket-1-2-3-4-my"
}

# SSM

variable "mysql_user" {
   description = "Test bucket name"
}

# Glue

variable "glue_database" {
   description = "Glue Database"
    type        = string
}

variable "glue_table" {
   description = "Glue table"
    type        = string
}

# ECR 

variable "ecr_values" {
  type        = any
  default     = {}
  description = "AWS ECR configuration"
}

# ECS
variable "ecs_values" {
  type        = any
  default     = {}
  description = "AWS ECS configuration"
}

variable "container" {
  type        = any
  default     = {}
  description = "Container configuration to deploy"
}

# Networking 
variable "vpc_id" {
  description = "VPC Id "

}
