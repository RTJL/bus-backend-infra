provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
    bucket = "bus-backend-infra"
    key    = "staging/terraform.tfstate"
    region = "ap-southeast-1"
  }
}

locals {
  api_origin_path         = "/${var.env}"
  website_endpoint        = trimprefix(module.website_bucket.website_endpoint, "https://")
  api_origin_without_http = trimprefix(data.aws_ssm_parameter.api_gateway_endpoint.value, "https://")
  api_gateway_domain_name = trimsuffix(local.api_origin_without_http, local.api_origin_path)
  ssm_map = {
    vpc_id = {
      ssm_name        = "/${var.project}/${var.env}/vpc/id"
      ssm_description = "VPC ID"
      ssm_value       = module.vpc.vpc_id
      ssm_type        = "String"
    },
    public_subnet = {
      ssm_name        = "/${var.project}/${var.env}/subnet/public/ids"
      ssm_description = "Public Subnet IDs"
      ssm_value       = join(",", module.vpc.public_subnet_ids)
      ssm_type        = "StringList"
    },
    private_subnet = {
      ssm_name        = "/${var.project}/${var.env}/subnet/private/ids"
      ssm_description = "Private Subnet IDs"
      ssm_value       = join(",", module.vpc.private_subnet_ids)
      ssm_type        = "StringList"
    },
    security_group_id = {
      ssm_name        = "/${var.project}/${var.env}/securityGroup/ids"
      ssm_description = "Security Group IDs"
      ssm_value       = join(",", [for o in module.sg : o.sg_id])
      ssm_type        = "StringList"
    },
    website_bucket_name = {
      ssm_name        = "/${var.project}/${var.env}/s3/website_bucket_name"
      ssm_description = "Website Bucket Name"
      ssm_value       = module.website_bucket.website_bucket_id
      ssm_type        = "String"
    }
  }
}

module "vpc" {
  source          = "../modules/vpc"
  project         = var.project
  env             = var.env
  cidr_block      = var.cidr_block
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  vpc_name        = "${var.project}-${var.env}"
  azs             = var.azs
}

module "website_bucket" {
  source              = "../modules/s3"
  project             = var.project
  env                 = var.env
  website_bucket_name = "bus-frontend-app-${var.env}"
}

module "sg" {
  source   = "../modules/security-group"
  for_each = var.sg_map

  project = var.project
  env     = var.env
  vpc_id  = module.vpc.vpc_id

  sg_name             = each.value.sg_name
  sg_description      = each.value.sg_description
  sg_ingress_protocol = each.value.sg_ingress_protocol
  sg_ingress_cidr     = each.value.sg_ingress_cidr
  sg_egress_cidr      = each.value.sg_egress_cidr
  sg_egress_protocol  = each.value.sg_egress_protocol
  sg_egress_port      = each.value.sg_egress_port
}

module "network" {
  source = "../modules/network"

  project                 = var.project
  env                     = var.env
  website_endpoint        = local.website_endpoint
  api_gateway_domain_name = local.api_gateway_domain_name
  api_origin_path         = local.api_origin_path
  www_domain_name         = var.www_domain_name
  acm_certificate_arn     = data.aws_ssm_parameter.cert_arn.value
  zone_id                 = data.aws_ssm_parameter.host_zone_id.value
}

module "ssm" {
  source   = "../modules/ssm-param"
  for_each = local.ssm_map

  project         = var.project
  env             = var.env
  ssm_name        = each.value.ssm_name
  ssm_description = each.value.ssm_description
  ssm_value       = each.value.ssm_value
  ssm_type        = each.value.ssm_type
}

data "aws_ssm_parameter" "cert_arn" {
  name            = "/bus-backend-infra/${var.env}/certManager/arn"
  with_decryption = true
}

data "aws_ssm_parameter" "api_gateway_endpoint" {
  name            = "/bus-backend-app/${var.env}/apiGateway/endpoint"
  with_decryption = true
}

data "aws_ssm_parameter" "host_zone_id" {
  name            = "/bus-backend-infra/${var.env}/route53/hostZoneId"
  with_decryption = true
}
