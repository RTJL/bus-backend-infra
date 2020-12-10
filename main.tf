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
  api_origin_path = "/${var.env}"
  api_origin_without_http = trimprefix(data.aws_ssm_parameter.api_gateway_endpoint.value, "https://")
  api_gateway_domain_name = trimsuffix(local.api_origin_without_http, local.api_origin_path)
}

resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = "${var.project}-${var.env}"
  }
}

resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(concat(var.public_subnets, [""]), count.index)
  availability_zone       = element(concat(var.azs, [""]), count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project}-${var.env}-public-subnet-${count.index}"
  }
}

resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(concat(var.private_subnets, [""]), count.index)
  availability_zone       = element(concat(var.azs, [""]), count.index)
  tags = {
    Name = "${var.project}-${var.env}-private-subnet-${count.index}"
  }
}

resource "aws_internet_gateway" "main_gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project}-${var.env}-gw"
  }
}

resource "aws_route_table" "main_public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_gw.id
  }
  tags = {
    Name = "${var.project}-${var.env}"
  }
}

resource "aws_route_table_association" "main_public" {
  count = length(var.public_subnets)

  subnet_id = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.main_public.id
}

resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat.id
  subnet_id = aws_subnet.public[0].id
  depends_on = [aws_internet_gateway.main_gw]
}

resource "aws_route_table" "main_private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }
  tags = {
    Name = "main-private-1"
  }
}

resource "aws_route_table_association" "main_private" {
  count = length(var.private_subnets)

  subnet_id = element(aws_subnet.private.*.id, count.index)
  route_table_id = aws_route_table.main_private.id
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

resource "aws_ssm_parameter" "vpc_id" {
  name = "/${var.project}/${var.env}/vpc/id"
  description = "VPC ID"
  type = "String"
  value = aws_vpc.main.id

  tags = {
    Name = "${var.project}-${var.env}"
  }
}

resource "aws_ssm_parameter" "subnet__public_id" {
   name = "/${var.project}/${var.env}/subnet/public/ids"
   description = "Public Subnet IDs"
   type = "StringList"
   value = join(",", aws_subnet.public.*.id)

    tags = {
     Name = "${var.project}-${var.env}"
   }
}

resource "aws_ssm_parameter" "subnet__private_id" {
  name = "/${var.project}/${var.env}/subnet/private/ids"
  description = "Private Subnet IDs"
  type = "StringList"
  value = join(",", aws_subnet.private.*.id)

  tags = {
    Name = "${var.project}-${var.env}"
  }
}

resource "aws_ssm_parameter" "security_group_id" {
  name = "/${var.project}/${var.env}/securityGroup/ids"
  description = "Security Group IDs"
  type = "StringList"
  value = join(",", [aws_security_group.allow-ssh.id, aws_security_group.allow-http.id])

  tags = {
    Name = "${var.project}-${var.env}"
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

resource "aws_route53_record" "monitoring" {
  zone_id = data.aws_ssm_parameter.host_zone_id.value
  name    = var.www_monitoring_domain_name
  type    = "A"
  ttl     = "300"
  records = [aws_instance.public.public_ip]
}

resource "aws_instance" "public" {
  ami           = data.aws_ssm_parameter.public_ec2_ami.value
  instance_type = var.instance_type

  subnet_id = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.allow-ssh.id, aws_security_group.allow-http.id]
  key_name = aws_key_pair.key_pair.key_name
  user_data = file("packer/scripts/start_services.sh")
}

resource "aws_key_pair" "key_pair" {
  key_name   = var.key_pair_name
  public_key = file("keys/${var.key_pair_name}.pub")
}

resource "aws_security_group" "allow-ssh" {
  vpc_id      = aws_vpc.main.id
  name        = "allow-ssh"
  description = "security group that allows ssh and all egress traffic"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = var.ssh_egress_protocol
    cidr_blocks = [var.ssh_egress_cidr]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = var.ssh_ingress_protocol
    cidr_blocks = [var.ssh_ingress_cidr]
  }
  tags = {
    Name = "allow-ssh"
  }
}

resource "aws_security_group" "allow-http" {
  vpc_id      = aws_vpc.main.id
  name        = "allow-http"
  description = "security group that allows ssh and all egress traffic"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = var.ssh_egress_protocol
    cidr_blocks = [var.ssh_egress_cidr]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = var.ssh_ingress_protocol
    cidr_blocks = [var.ssh_ingress_cidr]
  }
  tags = {
    Name = "allow-http"
  }
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id = "${var.project}-${var.env}-cache"
  engine = "redis"
  node_type = "cache.t2.micro"
  num_cache_nodes = 1
  parameter_group_name = "default.redis6.x"
  subnet_group_name = aws_elasticache_subnet_group.redis_subnet_group.name

  tags = {
    Name = "${var.project}-${var.env}"
  }
}

resource "aws_ssm_parameter" "elasticache_endpoint" {
  name = "/${var.project}/${var.env}/elasticache/endpoint"
  description = "Elasticache Endpoint"
  type = "SecureString"
  value = "${aws_elasticache_cluster.redis.cache_nodes.0.address}:${aws_elasticache_cluster.redis.cache_nodes.0.port}"

  tags = {
    Name = "${var.project}-${var.env}"
  }
}

resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "${var.project}-${var.env}-redis-subnet"
  subnet_ids = aws_subnet.private.*.id
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

data "aws_ssm_parameter" "public_ec2_ami" {
  name = "/bus-backend-infra/${var.env}/ec2/public_ami"
  with_decryption = true
}
