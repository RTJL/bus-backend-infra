resource "aws_security_group" "sg" {
  vpc_id      = var.vpc_id
  name        = var.sg_name
  description = var.sg_description
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = var.sg_egress_protocol
    cidr_blocks = var.sg_egress_cidr
  }

  ingress {
    from_port   = var.sg_egress_port
    to_port     = var.sg_egress_port
    protocol    = var.sg_ingress_protocol
    cidr_blocks = var.sg_ingress_cidr
  }
  tags = {
    project = var.project
    env     = var.env
    name    = var.sg_name
  }
}
