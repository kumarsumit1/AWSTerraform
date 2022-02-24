

output "s3_bucket_arn" {
  value = aws_s3_bucket.mybucket.arn
}

output "s3_bucket_name" {
   value = aws_s3_bucket.mybucket.id
}