resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name    = var.vpc_name
    project = var.project
    env     = var.env
  }
}

resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(concat(var.public_subnets, [""]), count.index)
  availability_zone       = element(concat(var.azs, [""]), count.index)
  map_public_ip_on_launch = true
  tags = {
    Name    = "${var.vpc_name}-public-subnet-${count.index}"
    project = var.project
    env     = var.env
  }
}

resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id            = aws_vpc.main.id
  cidr_block        = element(concat(var.private_subnets, [""]), count.index)
  availability_zone = element(concat(var.azs, [""]), count.index)
  tags = {
    Name    = "${var.vpc_name}-private-subnet-${count.index}"
    project = var.project
    env     = var.env
  }
}

resource "aws_internet_gateway" "main_gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name    = "${var.vpc_name}-gw"
    project = var.project
    env     = var.env
  }
}

resource "aws_route_table" "main_public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_gw.id
  }
  tags = {
    Name    = "${var.vpc_name}-public-rt"
    project = var.project
    env     = var.env
  }
}

resource "aws_route_table_association" "main_public" {
  count = length(var.public_subnets)

  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.main_public.id
}

resource "aws_instance" "nat_instance" {
  ami           = var.nat_ami
  instance_type = var.instance_type

  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.nat_instance_sg.id]
  key_name               = aws_key_pair.key_pair.key_name
  associate_public_ip_address = true
  source_dest_check = false

  tags = {
    Name    = "${var.vpc_name}-nat-ec2"
    project = var.project
    env     = var.env
  }
}

resource "aws_security_group" "nat_instance_sg" {
  vpc_id      = aws_vpc.main.id
  name        = "${var.vpc_name}-nat-sg"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.private_subnets
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.private_subnets
  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name    = "${var.vpc_name}-nat-sg"
    project = var.project
    env     = var.env
  }
}

resource "aws_key_pair" "key_pair" {
  key_name   = var.key_pair_name
  public_key = file("keys/${var.key_pair_name}.pub")
}

resource "aws_route_table" "main_private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    instance_id = aws_instance.nat_instance.id
  }
  tags = {
    Name    = "${var.vpc_name}-private-rt"
    project = var.project
    env     = var.env
  }
}

resource "aws_route_table_association" "main_private" {
  count = length(var.private_subnets)

  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = aws_route_table.main_private.id
}
