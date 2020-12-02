provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
    bucket = "bus-backend-infra"
    key    = "terraform.tfstate"
    region = "ap-southeast-1"
  }
}

locals {
  website_bucket_name = "bus-frontend-app-${var.env}"
  website_endpoint = trimprefix(aws_s3_bucket.website_bucket.website_endpoint, "https://")
  api_origin_path = "/dev"
  api_origin_without_http = trimprefix(data.aws_ssm_parameter.api_gateway_endpoint.value, "https://")
  api_gateway_domain_name = trimsuffix(local.api_origin_without_http, local.api_origin_path)
}

resource "aws_s3_bucket" "website_bucket" {
  bucket = local.website_bucket_name
  acl = "public-read"
  policy = data.aws_iam_policy_document.website_policy.json
  website {
    index_document = "index.html"
    error_document = "index.html"
  }
}

resource "aws_ssm_parameter" "website_bucket_name" {
  name = "/${var.project}/${var.env}/s3/website_bucket_name"
  description = "Website Bucket Name"
  type = "String"
  value = aws_s3_bucket.website_bucket.id

  tags = {
    Name = "${var.project}-${var.env}"
  }
}

resource "aws_cloudfront_distribution" "website_distribution" {
  origin {
    custom_origin_config {
      http_port = "80"
      https_port = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
    domain_name = local.website_endpoint
    origin_id = local.website_endpoint
  }

  origin {
    domain_name = local.api_gateway_domain_name
    origin_id = local.api_gateway_domain_name
    origin_path = local.api_origin_path

    custom_origin_config {
      http_port = "80"
      https_port = "443"
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  enabled = true
  default_root_object = "index.html"
  price_class = "PriceClass_200"

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.website_endpoint

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  ordered_cache_behavior {
    path_pattern = "api/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]
    compress = true
    default_ttl = 0
    max_ttl = 0
    min_ttl = 0
    smooth_streaming = false
    target_origin_id = local.api_gateway_domain_name
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      headers = ["Accept", "Authorization"]
      cookies {
        forward = "all"
      }
      query_string = true
    }
  }

  aliases = [ var.www_domain_name ]

  viewer_certificate {
    acm_certificate_arn = data.aws_ssm_parameter.cert_arn.value
    ssl_support_method = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_ssm_parameter.host_zone_id.value
  name    = var.www_domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.website_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.website_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

data "aws_iam_policy_document" "website_policy" {
  statement {
    actions = [
      "s3:GetObject"
    ]
    principals {
      identifiers = ["*"]
      type = "AWS"
    }
    resources = [
      "arn:aws:s3:::${local.website_bucket_name}/*"
    ]
  }
}

data "aws_ssm_parameter" "cert_arn" {
  name = "/bus-backend-infra/${var.env}/certManager/arn"
  with_decryption = true
}

data "aws_ssm_parameter" "api_gateway_endpoint" {
  name = "/bus-backend-app/${var.env}/apiGateway/endpoint"
  with_decryption = true
}

data "aws_ssm_parameter" "host_zone_id" {
  name = "/bus-backend-infra/${var.env}/route53/hostZoneId"
  with_decryption = true
}
