module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "lab3-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["ap-northeast-1a", "ap-northeast-1c"]
  private_subnets = ["10.0.0.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.1.0/24", "10.0.3.0/24"]

  enable_nat_gateway = true
}

resource "aws_security_group" "allow_tls" {
  name        = "Web Security Group"
  description = "Enable HTTP access"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description      = "Permit web requests"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Web Security Group"
  }
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  name = "Web Server 1"

  ami                    = "ami-06ee4e2261a4dc5c3"
  instance_type          = "t2.micro"
  key_name               = "yen-key"
  monitoring             = true
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  subnet_id              = module.vpc.public_subnets[0]
  user_data = <<EOF
#!/bin/bash

# Install Apache Web Server and PHP

yum install -y httpd mysql php

# Download Lab files

wget https://aws-tc-largeobjects.s3.us-west-2.amazonaws.com/CUR-TF-100-ACCLFO-2-9026/2-lab2-vpc/s3/lab-app.zip

unzip lab-app.zip -d /var/www/html/

# Turn on web server

chkconfig httpd on

service httpd start
  EOF
}