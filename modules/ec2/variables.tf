variable "ami" {
  description = "AMI ID"
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
variable "subnet_id" {
  description = "EC2 subnet ID"
  type        = string
}