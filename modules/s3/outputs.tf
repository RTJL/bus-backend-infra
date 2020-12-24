output "website_bucket_id" {
  description = "S3 bucket id for website"
  value       = aws_s3_bucket.website_bucket.id
}

output "website_endpoint" {
  description = "S3 bucket endpoint"
  value       = aws_s3_bucket.website_bucket.website_endpoint
}
