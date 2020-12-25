variable "project" {
  description = "Project name"
  type        = string
}
variable "env" {
  description = "Project env"
  type        = string
}
variable "vpc_id" {
  description = "VPC ID"
  type        = string
}
variable "sg_name" {
  description = "Security group name"
  type        = string
}
variable "sg_description" {
  description = "Security group description"
  type        = string
}
variable "sg_ingress_protocol" {
  description = "SSH security group ingress protcol"
  type        = string
}
variable "sg_ingress_cidr" {
  description = "SSH security group ingress cidr"
  type        = list(string)
}
variable "sg_egress_cidr" {
  description = "SSH security group egress cidr"
  type        = list(string)
}
variable "sg_egress_protocol" {
  description = "SSH security group egress protcol"
  type        = string
}
variable "sg_egress_port" {
  description = "Security group egress port"
  type        = number
}