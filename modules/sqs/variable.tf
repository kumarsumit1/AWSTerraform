
variable "sqs_queue_name" {
  type=string
  default = "${terraform.workspace}_kinesis"
}

variable "sqs_visibility_timeout_seconds" {
  default = 30
}

variable "kms_key_id" {
  type    = string
}

variable "sqs_kms_data_key_reuse_period_seconds" {
  default = 300
}

variable "sqs_delay_seconds" {
  default = 90
}

variable "sqs_max_message_size" {
  default = 2048
}

variable "sqs_message_retention_seconds" {
  default = 86400
}

variable "sqs_receive_wait_time_seconds" {
  default = 10
}
