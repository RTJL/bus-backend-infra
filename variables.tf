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
  description = "The CIDR block for the VPC"
  type        = string
}
variable "public_subnets" {
  description = "List of public subnets for the VPC"
  type        = list(string)
}
variable "private_subnets" {
  description = "List of private subnets for the VPC"
  type        = list(string)
}
variable "azs" {
  description = "List of availability zones names in the region"
  type        = list(string)
}
variable "repository_name" {
  description = "Respository Name"
  default = "bus-frontend-app"
}
variable "www_domain_name" {
  description = "Website domain name"
  type = string
}
variable "www_root_domain_name" {
  description = "Website root domain name"
  type = string
  default = "sgbus.tk"
}