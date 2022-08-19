# EC2 Module
resource "aws_instance" "ec2" {
  ami                    = var.ami_id
  instance_type          = var.type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_id
  key_name               = var.keypair_name
  tags = {
    Name = var.instance_name
  }
}