# https://hyperscience.com/tech-blog/running-cron-jobs-in-aws/
# https://github.com/hyperscience/tf-aws-cron-job/blob/main/main.tf

// Failure notification configuration (using Cloudwatch)
// -----------------------------------------------------
// We create an event rule that sends a message to an SNS Topic every time the task fails with a non-0 error code

resource "aws_cloudwatch_event_rule" "task_failure" {
  name        = "${local.ecs["service_name"]}_task_failure"
  description = "Watch for ${local.ecs["service_name"]} tasks that exit with non zero exit codes"

  event_pattern = <<EOF
  {
    "source": [
      "aws.ecs"
    ],
    "detail-type": [
      "ECS Task State Change"
    ],
    "detail": {
      "lastStatus": [
        "STOPPED"
      ],
      "stoppedReason": [
        "Essential container in task exited"
      ],
      "containers": {
        "exitCode": [
          {"anything-but": 0}
        ]
      },
      "clusterArn": ["${aws_ecs_cluster.cluster.arn}"],
      "taskDefinitionArn": ["${aws_ecs_task_definition.ecs_task.arn}"]
    }
  }
  EOF
}

resource "aws_sns_topic" "task_failure_sns" {
  name = "${local.ecs["service_name"]}_task_failure"
}


# One can use input to send messages or input_transformer
# resource "aws_cloudwatch_event_target" "sns_target" {
#   rule  = aws_cloudwatch_event_rule.task_failure.name
#   arn   = aws_sns_topic.task_failure_sns.arn
#   input = jsonencode(
#       { "Message" : "Task ${local.ecs["service_name"]} failed! Please check logs https://console.aws.amazon.com/cloudwatch/home#logsV2:log-groups/log-group/$252Fecs$252Ffargate/log-events " }
#       )
# }

# Sending message using input_transformer
# The sample json from which input_paths can be clculated from creating a dummy even rule 
# as it has some sample Event Jsons
# https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/CloudWatch-Events-Input-Transformer-Tutorial.html
# https://www.gitmemory.com/issue/terraform-providers/terraform-provider-aws/7280/545079909
resource "aws_cloudwatch_event_target" "sns_target" {
  rule = aws_cloudwatch_event_rule.task_failure.name
  arn  = aws_sns_topic.task_failure_sns.arn
  input_transformer {
    input_paths = {
      # For printing full details block
      #instance = "$.detail",
      rule     = "$.detail.startedBy",
      status   = "$.detail.lastStatus",
      reason   = "$.detail.stoppedReason",
    }
    input_template = "\"The event rule :  <rule> failed with state : <status>  and reason being : <reason> . Please check logs https://console.aws.amazon.com/cloudwatch/home#logsV2:log-groups/log-group/$252Fecs$252Ffargate/log-events\""
  }
}


data "aws_iam_policy_document" "task_failure" {

  statement {
    actions   = ["SNS:Publish"]
    effect    = "Allow"
    resources = [aws_sns_topic.task_failure_sns.arn]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_sns_topic_policy" "task_failure" {
  arn    = aws_sns_topic.task_failure_sns.arn
  policy = data.aws_iam_policy_document.task_failure.json
}
