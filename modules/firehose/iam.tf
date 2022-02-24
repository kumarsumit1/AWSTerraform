# IAM Role for Firehose
resource "aws_iam_role" "firehose_role" {
  name = "${terraform.workspace}-kinesis"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "firehose.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
}
EOF
}


data "aws_iam_policy_document" "firehose_policy_statements" {
  statement {
    effect = "Allow"
    actions = ["kinesis:DescribeStream",
      "kinesis:GetShardIterator",
      "kinesis:GetRecords",
      "kinesis:ListShards"
    ]
    resources = ["${var.kinesis_topic_name_arn}"]
  }

  statement {
    effect = "Allow"
    actions = ["s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject"
    ]
    resources = [
      "${var.s3_bucket_arn}",
      "${var.s3_bucket_arn}/*"
    ]
  }

  # statement {
  #   effect = "Allow"
  #   actions = ["kms:GenerateDataKey",
  #     "kms:Decrypt"
  #   ]
  #   resources = [
  #     "${var.kms_arn}"
  #   ]
  # }

  statement {
    effect    = "Allow"
    actions   = ["logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.firehose_log_group.arn}"]
  }

  # Required for transformation 
  statement {
    effect = "Allow"
    actions = ["glue:GetTable",
      "glue:GetTableVersion",
      "glue:GetTableVersions"
    ]
    resources = ["arn:aws:glue:${var.region}:${var.account_id}:catalog",
      aws_glue_catalog_database.kinesis_firehose_database.arn,
      aws_glue_catalog_table.firehose_table.arn
    ]
  }

  # Required for invoking Lambda function when to transform the data when input is not in json format 
  statement {
    effect = "Allow"
    actions = ["lambda:InvokeFunction",
      "lambda:GetFunctionConfiguration"
    ]
    resources = ["arn:aws:lambda:eu-west-1:123456789012:function:%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%"]
  }

}

resource "aws_iam_policy" "firehose_policy" {
  name   = "${terraform.workspace}_kinesis"
  path   = "/"
  policy = data.aws_iam_policy_document.firehose_policy_statements.json
}


resource "aws_iam_role_policy_attachment" "attach_kinesis_policy_to_kinesis_role" {
  role       = aws_iam_role.firehose_role.name
  policy_arn = aws_iam_policy.firehose_policy.arn
}



