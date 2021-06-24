# Metrices without dimensions

resource "aws_cloudwatch_log_group" "send_mail_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.sendmail_lambda.function_name}"
  tags              = local.default_tags
  retention_in_days = 5
}


# Number of messages processed by Lambda
resource "aws_cloudwatch_log_metric_filter" "send_mail_count_from_log" {
  name           = "send_mail_count"
  pattern        = "Email sent"
  log_group_name = aws_cloudwatch_log_group.send_mail_log_group.name

  metric_transformation {
    name          = "SendMailCount"
    namespace     = "SendEmail"
    value         = "5"
    default_value = "0"
  }
}

#Metrics with dimensions
#TODO



# http://stephenmann.io/post/setting-up-monitoring-and-alerting-on-amazon-aws-with-terraform/

resource "aws_sns_topic" "send_mail_sns_topic_notification" {
  name = "send_mail_sns_topic_notification"
  tags = local.default_tags
  # provisioner "local-exec" {
  #   command = "aws sns subscribe --topic-arn ${self.arn} --protocol email --notification-endpoint ${var.alarms_email}"
  # }
}

# https://www.blog.fusion-techno.com/?p=315
# Alarms on metrics without dimension
# Alarm to check if less than one mail has been sent in a days
resource "aws_cloudwatch_metric_alarm" "send_mail_dimensionless_alarm" {
  alarm_name          = "send_mail_dimensionless_alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  threshold           = "1"
  treat_missing_data  = "breaching"
  alarm_description   = "send mail dimensionless alarm"
  alarm_actions = [
    aws_sns_topic.send_mail_sns_topic_notification.arn
  ]
  metric_name = "EmailSentDimensionless"
  namespace   = "SendEmail"
  statistic   = "Sum"
  period      = "86400"
  tags        = local.default_tags
}


# Alarms on metrics with dimension
# To check if more than 5 mails are being triggered per 5 mins
resource "aws_cloudwatch_metric_alarm" "send_mail_with_dimension_alarm" {
  alarm_name          = "send_mail_with_dimension_alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  treat_missing_data  = "breaching"
  threshold           = "5"
  alarm_description   = "send mail with dimension alarm"
  alarm_actions = [
    aws_sns_topic.send_mail_sns_topic_notification.arn
  ]
  tags = local.default_tags

  metric_name = "EmailSentDimensions"
  period      = "300"
  statistic   = "Sum"
  namespace   = "SendEmail"
  dimensions = {
    Sender   = "ALL",
    Reciever = "${var.alarms_email}"
  }
}


# Alarms on event created for triggering Lambda function

resource "aws_cloudwatch_metric_alarm" "send_mail_failed_job_alarm" {
  alarm_name          = "send_mail_failed_job_alarm"
  comparison_operator = "GreaterThanThreshold"
  threshold           = "0"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  treat_missing_data  = "breaching"
  alarm_description   = "send mail failed job alarm"
  alarm_actions = [
    aws_sns_topic.send_mail_sns_topic_notification.arn
  ]
  namespace   = "AWS/Events"
  metric_name = "FailedInvocations"
  dimensions = {
    RuleName =aws_cloudwatch_event_rule.cloudwatch_event_scheduler_cron.name
  }
  statistic   = "Sum"
  period      = "86400"
  tags        = local.default_tags
}
