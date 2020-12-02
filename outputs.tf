output "website_bucket_name" {
  description = "Static website bucket name"
  value = aws_s3_bucket.website_bucket.id
}

output "website_bucket_arn" {
  description = "Static website bucket ARN"
  value = aws_s3_bucket.website_bucket.arn
}
