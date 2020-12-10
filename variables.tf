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
variable "www_monitoring_domain_name" {
  description = "Monitoring domain name"
  type = string
}
variable "instance_type" {
  description = "EC2 instance type"
  type = string
  default = "t2.micro"
}
variable "ami" {
  description = "EC2 AMI"
  type = string
  default = "ami-0d728fd4e52be968f"
}
variable "key_pair_name" {
  description = "EC2 Keypair"
  type = string
}
variable "ssh_ingress_protocol" {
  description = "SSH security group ingress protcol"
  type = string
}
variable "ssh_ingress_cidr" {
  description = "SSH security group ingress cidr"
  type = string
}
variable "ssh_egress_cidr" {
  description = "SSH security group egress cidr"
  type = string
}
variable "ssh_egress_protocol" {
  description = "SSH security group egress protcol"
  type = string
}