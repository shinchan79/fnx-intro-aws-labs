provider "aws" {
  region = "ap-northeast-1"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "lab9-vpc"
  cidr = "10.99.0.0/18"

  azs              = ["ap-northeast-1a", "ap-northeast-1c"]
  public_subnets   = ["10.99.0.0/24", "10.99.2.0/24"]
  private_subnets  = ["10.99.3.0/24", "10.99.5.0/24"]
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "lab7-sg"
  description = "Security group for example usage with EC2 instance"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "all-icmp", "ssh-tcp", "mysql-tcp"]
  egress_rules        = ["all-all"]
}

resource "aws_db_instance" "mysql" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "8.0.23"
  instance_class         = "db.t3.micro"
  db_name                   = var.dbname
  username               = var.username
  password               = var.password
  parameter_group_name   = "default.mysql8.0"
  vpc_security_group_ids = [module.security_group.security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.mysql.name
  skip_final_snapshot    = true
}

resource "aws_db_subnet_group" "mysql" {
  name       = "db_subnetgroup"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name = "db_subnetgroup"
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*-x86_64-gp2"]
  }
}


data "template_file" "this" {
  template =<<EOF
#!/bin/bash
yum update -y
yum install -y mysql
EOF
}

module "ec2" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name = "lab7-ec2"

  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t2.micro"
  availability_zone           = "ap-northeast-1a"
  subnet_id                   = element(module.vpc.public_subnets, 0)
  vpc_security_group_ids      = [module.security_group.security_group_id]
  associate_public_ip_address = true
  key_name = "yen-key"
  user_data = "${base64encode(data.template_file.this.rendered)}"
}

output "Login" {
  value = "ssh -i yenpasona-key ec2-user@${module.ec2.public_ip}"
}

output "db_access_from_ec2" {
  value = "mysql -h ${aws_db_instance.mysql.address} -P ${aws_db_instance.mysql.port} -u ${var.username} -p${var.password}"
}