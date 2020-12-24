variable "project" {
  description = "Project Name"
  type        = string
}
variable "env" {
  description = "Environment Name"
  type        = string
}
variable "region" {
  description = "AWS Region"
  type        = string
}
variable "cidr_block" {
  description = "CIDR block for VPC"
  type        = string
}
variable "public_subnets" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
}
variable "private_subnets" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
}
variable "azs" {
  description = "List of availability zones names in the region"
  type        = list(string)
}
variable "sg_map" {
  description = "Map of security group name to config"
  type        = map
}


variable "repository_name" {
  description = "Respository Name"
  default     = "bus-frontend-app"
}
variable "www_domain_name" {
  description = "Website domain name"
  type        = string
}
variable "www_root_domain_name" {
  description = "Website root domain name"
  type        = string
  default     = "sgbus.tk"
}
variable "www_monitoring_domain_name" {
  description = "Monitoring domain name"
  type        = string
}
variable "key_pair_name" {
  description = "EC2 Keypair"
  type        = string
}