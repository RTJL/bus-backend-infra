output "website_bucket_name" {
  description = "Static website bucket name"
  value = aws_s3_bucket.website_bucket.id
}

output "website_bucket_arn" {
  description = "Static website bucket ARN"
  value = aws_s3_bucket.website_bucket.arn
}

output "public_host_ip" {
  description = "Public EC2 host IP"
  value = aws_instance.public.public_ip
}

output "public_host_dns" {
  description = "Public EC2 host DNS"
  value = aws_instance.public.public_dns
}

output "elasticache_endpoint" {
  description = "Elasticache endpoint"
  value = "${aws_elasticache_cluster.redis.cache_nodes.0.address}:${aws_elasticache_cluster.redis.cache_nodes.0.port}"
}

# output "monitoring_endpoint" {
#   description = "Monitoring endpoint"
#   value = aws_route53_record.monitoring.name
# }