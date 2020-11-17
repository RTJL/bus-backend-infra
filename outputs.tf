output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}

output "public_subnet_0" {
  description = "Public Subnet 0"
  value       = aws_subnet.public[0].id
}

output "public_subnet_1" {
  description = "Public Subnet 1"
  value       = aws_subnet.public[1].id
}

output "private_subnet_0" {
  description = "Private Subnet 0"
  value       = aws_subnet.private[0].id
}

output "private_subnet_1" {
  description = "Private Subnet 1"
  value       = aws_subnet.private[1].id
}

output "public_subnet_sg" {
  description = "Public Subnet Security Group"
  value       = aws_security_group.default_public.id
}