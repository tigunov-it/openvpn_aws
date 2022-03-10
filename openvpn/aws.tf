provider "aws" {
  region = "eu-north-1"
  }

data "aws_ami" "latest_ubuntu" { //Динамически получаем ami последней версии ubuntu
  owners = ["099720109477"]
  most_recent = true
  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_instance" "sht_vpn" {
  ami = data.aws_ami.latest_ubuntu.id
  instance_type = "t3.nano"
  subnet_id = "subnet-0b8087d4f90f4a7d2"
  vpc_security_group_ids = [aws_security_group.allow_ssh_openvpn.id]
  user_data = file("bashscript.sh")
  key_name = "aws_stockholm"
    tags = {
     "Name" = "sht_vpn"
   }
}

resource "aws_security_group" "allow_ssh_openvpn" {
  name        = "allow_ssh_openvpn"
  description = "Allow ssh and openvpv inbound traffic"
  vpc_id      = "vpc-0db8096135d8fe07e"

  ingress {
    description      = "ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  ingress {
    description      = "openvpn"
    from_port        = 1194
    to_port          = 1194
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_ssh_openvpn"
  }
}