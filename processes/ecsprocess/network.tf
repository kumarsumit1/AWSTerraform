
# https://github.com/vthub/scheduled-ecs-task/blob/master/infrastructure/main.tf

#The aws_default_vpc behaves differently from normal resources, 
# in that Terraform does not create this resource, but instead "adopts" it into management.

# resource "aws_default_vpc" "default" {
# }

# If default VPC is not present in your account then fetch the value of 
# VPC present in you account
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc
data "aws_vpc" "selected" {
  id = var.vpc_id
}

data "aws_subnet_ids" "subnets" {
  #vpc_id = aws_default_vpc.default.id
  vpc_id = data.aws_vpc.selected.id
}


# https://github.com/vthub/scheduled-ecs-task/blob/master/infrastructure/ecs.tf
resource "aws_security_group" "ecs" {
  vpc_id = data.aws_vpc.selected.id
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }
}

