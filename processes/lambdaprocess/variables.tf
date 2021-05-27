#Main.tf variables

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "remote_state_bucket" {
  description = "S3 bucket for storing state file"
}

variable "remote_state_table" {
  description = "Dynamo DB Table for storing the lock"
}

variable "remote_state_key" {
  description = "Key for remote state table"
}

# Tag Details 

variable "resource_department" {
  description = "Name of the department for which resource has been provisioned"
  
}

variable "resource_team" {
  description = "Team for which resouce has been provisioned"
}

variable "resource_cost_center" {
  description = "Cost center billiabiltiy"
}

variable "use_case_name" {
  description = "Use case name of the stack"
}

variable "use_case_version" {
  description = "use case version of the stack"
}

variable "env_type" {
  description = "env type"
}

variable "env_name" {
  description = "env name"
  
}

variable "availibility_hours" {
  description = "resouce availiability"
  
}

variable "region_name" {
  description = "Location in which the resource is hosted"
}
