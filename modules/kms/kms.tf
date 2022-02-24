# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket

# https://github.com/ned1313/terraform-tuesdays/tree/main/2021-04-13-AWS-KMS

resource "aws_kms_key" "cipher" {
  description = "Encrytption key for dev testing"
  key_usage = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  enable_key_rotation = true
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "cipher" {
  name = var.alias_name
  target_key_id = aws_kms_key.cipher.key_id
}

data "aws_kms_key" "sse_key" {
  key_id = var.alias_name

  depends_on = [
    aws_kms_key.cipher,
  ]
}

