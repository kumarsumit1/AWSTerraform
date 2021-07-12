
locals {
  region = var.aws_region
  ecr_defaults = {
    repository_name = "app-registry"
  }
  ecr = merge(local.ecr_defaults, var.ecr_values)


ecs_defaults = {
    cluster_name = "ecs-cluster"
    service_name = "ecs-service"
  }
  ecs = merge(local.ecs_defaults, var.ecs_values)

  container_defaults = {
    name  = "mycontainer"
    image = "app-registry"
    ports = [80]
  }
  container = merge(local.container_defaults, var.container)

}