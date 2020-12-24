resource "aws_instance" "public" {
  ami           = var.ami
  instance_type = var.instance_type

  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.sg_ids
  key_name               = aws_key_pair.key_pair.key_name
  user_data              = file("../packer/scripts/start_services.sh")
}

resource "aws_key_pair" "key_pair" {
  key_name   = var.key_pair_name
  public_key = file("../keys/${var.key_pair_name}.pub")
}
