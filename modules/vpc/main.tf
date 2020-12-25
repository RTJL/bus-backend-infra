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
    Name    = var.vpc_name
    project = var.project
    env     = var.env
  }
}

resource "aws_route_table_association" "main_public" {
  count = length(var.public_subnets)

  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.main_public.id
}

resource "aws_eip" "nat" {
  vpc = true
  tags = {
    project = var.project
    env     = var.env
  }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  depends_on    = [aws_internet_gateway.main_gw]
  tags = {
    project = var.project
    env     = var.env
  }
}

resource "aws_route_table" "main_private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }
  tags = {
    Name    = "main-private-1"
    project = var.project
    env     = var.env
  }
}

resource "aws_route_table_association" "main_private" {
  count = length(var.private_subnets)

  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = aws_route_table.main_private.id
}
