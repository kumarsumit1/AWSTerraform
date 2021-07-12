# https://github.com/tbobm/tf-ecr-ecs-gh-deploy/blob/main/terraform/ecr.tf

resource "aws_ecr_repository" "base_repository" {
  name = local.ecr["repository_name"]
  image_tag_mutability = "MUTABLE"
}


resource "aws_ecr_repository_policy" "policy" {
  repository = aws_ecr_repository.base_repository.name
  policy     = <<EOF
  {
    "Version": "2008-10-17",
    "Statement": [
      {
        "Sid": "adds full ecr access to the ${local.ecr["repository_name"]} repository",
        "Effect": "Allow",
        "Principal": "*",
        "Action": [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetLifecyclePolicy",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
      }
    ]
  }
  EOF
}