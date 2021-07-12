# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket

# https://github.com/ned1313/terraform-tuesdays/tree/main/2021-04-13-AWS-KMS

resource "aws_kms_key" "cipher" {
  description = "Ciphertext"
  key_usage = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  enable_key_rotation = true
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "cipher" {
  name = "alias/cipherkey"
  target_key_id = aws_kms_key.cipher.key_id
}

data "aws_kms_key" "sse_key" {
  key_id = "alias/cipherkey"

  depends_on = [
    aws_kms_key.cipher,
  ]
}

resource "aws_s3_bucket" "mybucket" {
  bucket = var.my_bucket
  acl    = "private"


  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = data.aws_kms_key.sse_key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}