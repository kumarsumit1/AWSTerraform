output "ecr_url" {
  value       = aws_ecr_repository.base_repository.repository_url
  description = "The ECR repository URL"
}

# output "default_vpc" {
#   description= "default_vpc"
#   value = aws_default_vpc.default
# }

# output "default_subnets" {
#   description = "default_subnets"
#   value = aws_subnet_ids.subnets
# }

output "default_security_group" {
  description = "value"
  value = aws_security_group.ecs
}