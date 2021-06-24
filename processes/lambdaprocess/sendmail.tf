# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function 
# https://gist.github.com/smithclay/e026b10980214cbe95600b82f67b4958


data "archive_file" "sendmail_lambda_code_zip" {
  type = "zip"
  #source_dir  = "sendmail/hello_world"
  source_file = "sendmail/hello_world/app.py"
  output_path = "sendmail.zip"
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda_sendmail"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy

resource "aws_iam_policy" "bucket_policy" {
  name        = "read_bucket_policy"
  path        = "/"
  description = "My test policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:*",
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.mybucket.arn}",
          "${aws_s3_bucket.mybucket.arn}/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "kms:GenerateDataKey",
          "kms:Encrypt",
          "kms:Decrypt"
        ],
        "Resource" : [
          "${aws_kms_key.mykey.arn}"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "bucket_policy_attachment" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.bucket_policy.arn
}

# Create policy for CloudWatch log too, now this can be done as policy was created previously with full JSONs
# Or one can simply mention the ARNs of such "standard" AWS policy and attach it to role
# This is more "cleaner approach" and is somewhat "more standard" as per AWS is concerned.
# For example here you would need AWSLambdaBasicExecutionRole policy for creating log in Cloudwach.

resource "aws_iam_role_policy_attachment" "cloudwatch_log_creation_policy_attachment" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}



resource "aws_iam_policy" "cloudwatch_metric_policy" {
  name        = "cloudwatch_metric_policy"
  path        = "/"
  description = "cloudwatch metric policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "cloudwatch:PutMetricData",
        ]
        Effect = "Allow"
        Resource = ["*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_metric_policy_attachment" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.cloudwatch_metric_policy.arn
}

resource "aws_lambda_function" "sendmail_lambda" {
  filename      = "sendmail.zip"
  function_name = "sendmail_lambda"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "app.lambda_handler"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  # Option 1
  #source_code_hash = filebase64sha256("sendmail.zip")
  #Option 2
  source_code_hash = data.archive_file.sendmail_lambda_code_zip.output_base64sha256
  runtime          = "python3.7"

  environment {
    variables = {
      foo    = "bar"
      bucket = aws_s3_bucket.mybucket.id
    }
  }
}

#Create a event in cloud watch
# Full process : https://openupthecloud.com/terraform-lambda-scheduled-event/
# At least one of schedule_expression or event_pattern is required
# For scheduling using schedule_expression
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule
# This event rule will create three entries in cloudwatch under namespace Events 
# One can draw graphs or create alarms from there.


resource "aws_cloudwatch_event_rule" "cloudwatch_event_scheduler_cron" {
  name                = "cloudwatch_event_scheduler_cron"
  description         = "Lambda trigger  scheduling"
  schedule_expression = "cron(5,15,25,35,45,55 * * * ? *)" # every 5,15,25,35,45,55 minutes 
  is_enabled = true
}



resource "aws_cloudwatch_event_target" "cloudwatch_event_cron_lambda_association" {
  arn  = aws_lambda_function.sendmail_lambda.arn
  rule = aws_cloudwatch_event_rule.cloudwatch_event_scheduler_cron.name
}


resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda_function" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sendmail_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cloudwatch_event_scheduler_cron.arn
}


