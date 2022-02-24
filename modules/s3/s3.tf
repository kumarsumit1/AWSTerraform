
resource "aws_s3_bucket" "mybucket" {
  bucket = var.bucket_name
  acl    = "private"


  # server_side_encryption_configuration {
  #   rule {
  #     apply_server_side_encryption_by_default {
  #       kms_master_key_id = var.kms_arn
  #       sse_algorithm     = "aws:kms"
  #     }
  #   }
  # }


}


#Default bucket policy to restrict access
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block
resource "aws_s3_bucket_public_access_block" "default_bucket_policy" {
  bucket                  = aws_s3_bucket.mybucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}