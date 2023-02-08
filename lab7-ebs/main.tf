provider "aws" {
  region = "ap-northeast-1"
}


module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "lab7-vpc"
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
  ingress_rules       = ["http-80-tcp", "all-icmp", "ssh-tcp"]
  egress_rules        = ["all-all"]
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*-x86_64-gp2"]
  }
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
  key_name = "yenpasona-key"
}

resource "aws_volume_attachment" "this" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.this.id
  instance_id = module.ec2.id
}

resource "aws_ebs_volume" "this" {
  availability_zone = "ap-northeast-1a"
  size              = 1
}

resource "aws_ebs_snapshot" "example_snapshot" {
  volume_id = aws_ebs_volume.this.id
}