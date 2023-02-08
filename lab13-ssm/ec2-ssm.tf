provider "aws" {
  profile = "default"
  region  = "ap-northeast-1"
}

data "aws_iam_policy" "ssm_ec2" {
  name = "AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role" "ssm_ec2" {
  name = "ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "RoleForEC2"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy_attachment" "ssm_ec2" {
  name = "ssm-ec2-attachment"
  roles      = [aws_iam_role.ssm_ec2.name]
  policy_arn = data.aws_iam_policy.ssm_ec2.arn
}

resource "aws_iam_instance_profile" "ssm_ec2" {
  name = "ssm-ec2-profile"
  role = aws_iam_role.ssm_ec2.name
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

  name = "lab13-ec2"

  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t2.micro"
  availability_zone           = "ap-northeast-1d"
  subnet_id                   = "subnet-0783d40404e54a399"
  vpc_security_group_ids      = [module.security_group.security_group_id]
  associate_public_ip_address = true
  key_name = "yenpasona-key"
  iam_instance_profile = aws_iam_instance_profile.ssm_ec2.id

  tags = {
    Name        = "linux_test"
    Environment = "test"
    "Patch Group" = "test-amazon-linux"
  }
}

module "ec2_2" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name = "lab13-ec2"

  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t2.micro"
  availability_zone           = "ap-northeast-1d"
  subnet_id                   = "subnet-0783d40404e54a399"
  vpc_security_group_ids      = [module.security_group.security_group_id]
  associate_public_ip_address = true
  key_name = "yenpasona-key"
  iam_instance_profile = aws_iam_instance_profile.ssm_ec2.id

  tags = {
    Name        = "linux_prod"
    Environment = "prod"
    "Patch Group" = "prod-amazon-linux"
  }
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "lab7-sg"
  description = "Security group for example usage with EC2 instance"
  vpc_id      = "vpc-0e002ea9920b93e82"

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "all-icmp", "ssh-tcp", "mysql-tcp"]
  egress_rules        = ["all-all"]
}