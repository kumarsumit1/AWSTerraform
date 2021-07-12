# https://particule.io/en/blog/cicd-ecr-ecs/
# Create a ecs cluster
resource "aws_ecs_cluster" "cluster" {
  name               = local.ecs["cluster_name"]  # "ecs-cluster"
  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = "100"
  }
}


# roles and log location detials and ssm access 
# https://www.chakray.com/creating-fargate-ecs-task-aws-using-terraform/

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs_role_for_executing_the_container_itself"
 
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# If any secrets are also being passed as Docker Environment variable 
# the one policy for reading secerets from SSM should also be added with task execution
# https://mobycast.fm/secrets-handling-for-containerized-applications-running-on-ecs/

resource "aws_iam_policy" "passing_secret_values_as_docker_env_var" {
  name = "passing_secret_values_as_docker_env_var"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameters"
            ],
            "Resource": [
              "${data.aws_ssm_parameter.mysql_password.arn}"
            ]
        }
    ]
}  
  EOF
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_attachment_for_ssm" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.passing_secret_values_as_docker_env_var.arn
}


#role that is need for task while running, for eg the docker code may need access to s3
resource "aws_iam_role" "ecs_task_role" {
  name = "task-role-required-while-running"
 
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

# resource "aws_iam_role_policy_attachment" "policy_attachment_for_reading_s3" {
#   role       = "${aws_iam_role.ecs_task_role.name}"
#   policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
# }

# Since the bucket is encrypted hence will have to use decrypt policy too

resource "aws_iam_policy" "read_encrypted_s3_bucket" {
  name = "read_encrypted_s3_bucket"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
              "s3:GetObject",
              "kms:Decrypt"
            ],
            "Resource": [
              "${data.aws_kms_key.sse_key.arn}",
              "${aws_s3_bucket.mybucket.arn}",
              "${aws_s3_bucket.mybucket.arn}/*"
            ]
        }
    ]
}  
  EOF
}

resource "aws_iam_role_policy_attachment" "policy_attachment_for_encrypted_s3" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.read_encrypted_s3_bucket.arn
}

# ResourceNotFoundException: The specified log group does not exist. : exit status 1
resource "aws_cloudwatch_log_group" "create_a_log_group_for_logs" {
  name              = "/ecs/fargate"
  retention_in_days = 7
}



# Create a task which can then be assigned to a service to be launched in a cluster
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition

# Pass SSM secerets 
# https://www.chakray.com/creating-fargate-ecs-task-aws-using-terraform/

resource "aws_ecs_task_definition" "ecs_task" {
  family = "test-service"
  requires_compatibilities = [
    "FARGATE",
  ]
  execution_role_arn    = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn         = aws_iam_role.ecs_task_role.arn
  network_mode          = "awsvpc"
  cpu                   = 256
  memory                = 512
  container_definitions = jsonencode([
    {
    name      = local.container.name
    image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${aws_ecr_repository.base_repository.name}:v1.0.0"
    essential = true
    portMappings = [
    for port in local.container.ports :
        {
          containerPort = port
          hostPort      = port
        }
      ]
    environment = [
            {"name": "BUCKET_NAME", "value": "${var.my_bucket}"},
            {"name": "VARNAME1", "value": "VARVAL1"}
        ]
    secrets = [
          {
          "name": "database/mysql/password",
          "valueFrom": "${data.aws_ssm_parameter.mysql_password.arn}"
          }
      ]
    logConfiguration = {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-region" : "eu-west-1",
                    "awslogs-group" : "/ecs/fargate",
                    "awslogs-stream-prefix" : "task"
                }
            }   
    }
  ])
}

# Service and scheduling of ECS job
# https://vthub.medium.com/running-ecs-fargate-tasks-on-a-schedule-fd1ca428e669
# Note change since 1.4 : Launch tasks into a "public subnet, with a public IP address", 
# so that they can communicate to ECR and other backing services using an internet gateway
# For more read : https://stackoverflow.com/questions/61265108/aws-ecs-fargate-resourceinitializationerror-unable-to-pull-secrets-or-registry


resource "aws_ecs_service" "service" {
  name                               = local.ecs["service_name"] 
  task_definition                    = aws_ecs_task_definition.ecs_task.arn
  cluster                            = aws_ecs_cluster.cluster.id
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  desired_count                      = 0
  launch_type                        = "FARGATE"
  network_configuration {
    subnets          = data.aws_subnet_ids.subnets.ids
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs.id]
  }
}


resource "aws_cloudwatch_event_rule" "scheduled_task" {
  name                = "scheduled-ecs-event-rule"
  schedule_expression = "rate(5 minutes)"
  is_enabled          = false   
}


resource "aws_cloudwatch_event_target" "scheduled_task" {
  target_id = "scheduled-ecs-target"
  rule      = aws_cloudwatch_event_rule.scheduled_task.name
  arn       = aws_ecs_cluster.cluster.arn
  role_arn  = aws_iam_role.scheduled_task_cloudwatch.arn

  ecs_target {
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.ecs_task.arn
    launch_type         = "FARGATE"
    network_configuration {
      subnets          = data.aws_subnet_ids.subnets.ids
      assign_public_ip = true
      security_groups  = [aws_security_group.ecs.id]
    }
  }
}


# To run scheduled cloudwatch events we need cloudwath role and ecs task execution policy
# https://github.com/vthub/scheduled-ecs-task/blob/master/infrastructure/iam.tf

resource "aws_iam_role" "scheduled_task_cloudwatch" {
  name               = "${local.ecs["service_name"]}-cloudwatch-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "scheduled_task_cloudwatch_policy" {
  name   = "${local.ecs["service_name"]}-cloudwatch-policy"
  role   = aws_iam_role.scheduled_task_cloudwatch.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:RunTask"
      ],
      "Resource": [
        "${replace(aws_ecs_task_definition.ecs_task.arn, "/:\\d+$/", ":*")}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": "iam:PassRole",
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}



#For monitoring the ECS job

# https://github.com/hyperscience/tf-aws-cron-job/blob/main/main.tf

