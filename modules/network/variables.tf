variable "project" {
  description = "Project Name"
  type        = string
}
variable "env" {
  description = "Environment Name"
  type        = string
}
variable "website_endpoint" {
  description = "Website endpoint URL"
  type        = string
}
variable "api_gateway_domain_name" {
  description = "API endpoint URL"
  type        = string
}
variable "api_origin_path" {
  description = "API endpoint origin path"
  type        = string
}
variable "www_domain_name" {
  description = "Website domain name"
  type        = string
}
variable "acm_certificate_arn" {
  description = "ACM cert ARN"
  type        = string
}
variable "zone_id" {
  description = "Route53 zone ID"
  type        = string
}
