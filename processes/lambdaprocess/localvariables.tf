locals {
  common_tags = {
    "Resource:department" = var.resource_department
    "Resource:team"       = var.resource_team
    "Resource:costCenter" = var.resource_cost_center
    "Usecase:name"        = var.use_case_name
    "Usecase:version"     = var.use_case_version
    "Env:type"            = var.env_type
    "Env:name"            = var.env_name
    "Availability:hours"  = var.availibility_hours
    "Region:name"         = var.region_name
    "Terraform"           = "True"
  }
}
