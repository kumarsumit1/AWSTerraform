variable "account_id" {
    type = string
  description = "account id for getting arn of catalog"
}
variable "firehose_destination" {
  type = string
  default = "extended_s3"
}

variable "kinesis_topic_name_arn" {
  type = string
}

variable "s3_bucket_arn" {
   type = string
   description = "Name of the bucket ARN "
}


variable "s3_bucket_name" {
   type = string
   description = "Name of the bucket "
}


variable "region" {
   type = string
   description = "Name of the region "
  
}
# variable "kms_arn" {
#   type = string
# }


variable "firehose_buffer_size" {
  default = 64
}

variable "firehose_buffer_interval" {
  default = 65
}

// UNCOMPRESSED , ZIP
variable "firehose_compression_format" {
  type    = string
  default = "UNCOMPRESSED"
}

