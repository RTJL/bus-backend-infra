variable "project" {
  description = "Project Name"
  type        = string
}
variable "env" {
  description = "Environment Name"
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
variable "vpc_name" {
  description = "VPC name"
  type        = string
}
variable "azs" {
  description = "List of availability zones names in the region"
  type        = list(string)
}
variable "nat_ami" {
  description = "NAT AMI ID"
  type        = string
}
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}
variable "sg_ids" {
  description = "Security group IDs"
  type        = list(string)
}
variable "key_pair_name" {
  description = "EC2 Keypair"
  type        = string
}
