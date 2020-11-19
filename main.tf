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

resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "${var.project}-vpc-${var.env}"
  }
}

resource "aws_ssm_parameter" "vpc_id" {
  name = "/${var.project}/${var.env}/vpc/id"
  description = "VPC ID"
  type = "SecureString"
  value = aws_vpc.this.id

  tags = {
    Name = "${var.project}-vpc-${var.env}"
  }
}

resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = element(concat(var.public_subnets, [""]), count.index)
  availability_zone       = element(concat(var.azs, [""]), count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project}-public-${count.index}-${var.env}"
  }
}

resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = element(concat(var.private_subnets, [""]), count.index)
  availability_zone       = element(concat(var.azs, [""]), count.index)
  tags = {
    Name = "${var.project}-private-${count.index}-${var.env}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project}-rt-${var.env}"
  }
}
resource "aws_route" "public_igw_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id

  timeouts {
    create = "5m"
  }
}
resource "aws_route_table_association" "public" {
  count = length(var.public_subnets)

  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project}-igw-${var.env}"
  }
}

resource "aws_security_group" "default_public" {
  name        = "${var.project}_default_public_sg-${var.env}"
  description = "${var.project} default public SG"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow http access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}_public_sg-${var.env}"
  }
}
