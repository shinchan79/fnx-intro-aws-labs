provider "aws" {
  region = "ap-northeast-1"
}

locals {
  azs = ["ap-northeast-1a", "ap-northeast-1c"]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "lab8-vpc"
  cidr = "10.99.0.0/18"

  azs              = ["ap-northeast-1a", "ap-northeast-1c"]
  public_subnets   = ["10.99.0.0/24", "10.99.2.0/24"]
  private_subnets  = ["10.99.3.0/24", "10.99.5.0/24"]

  enable_dns_hostnames = true
  enable_dns_support   = true
}

module "efs" {
  source = "terraform-aws-modules/efs/aws"

  # File system
  name           = "lab8-efs"

  performance_mode                = "generalPurpose"
  throughput_mode                 = "provisioned"
  provisioned_throughput_in_mibps = 24

  lifecycle_policy = {
    transition_to_ia                    = "AFTER_30_DAYS"
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  # Mount targets / security group
  mount_targets              = { for k, v in zipmap(local.azs, module.vpc.private_subnets) : k => { subnet_id = v } }
  security_group_description = "Example EFS security group"
  security_group_vpc_id      = module.vpc.vpc_id
  security_group_rules = {
    vpc = {
      # relying on the defaults provdied for EFS/NFS (2049/TCP + ingress)
      description = "NFS ingress from VPC private subnets"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  
  # File system policy
  attach_policy                      = true
  bypass_policy_lockout_safety_check = false
  policy_statements = [
    {
      sid     = "Example"
      actions = ["elasticfilesystem:ClientMount", "elasticfilesystem:ClientRootAccess", "elasticfilesystem:ClientWrite"]
      principals = [
        {
          type        = "AWS"
          identifiers = ["*"]
        }
      ]
    }
  ]

  # Access point(s)
  access_points = {
    root_example = {
      root_directory = {
        path = "/example"
        creation_info = {
          owner_gid   = 1001
          owner_uid   = 1001
          permissions = "755"
        }
      }
    }
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

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "lab7-sg"
  description = "Security group for example usage with EC2 instance"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "all-icmp", "nfs-tcp", "ssh-tcp"]
  egress_rules        = ["all-all"]
}

resource "aws_instance" "example" {
  ami = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  availability_zone = "ap-northeast-1a"
  subnet_id = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [module.security_group.security_group_id]
  key_name = "yen-key"
  
  lifecycle {
      ignore_changes = [ami]
    }
}

resource "null_resource" "local2" {

 connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("yen-key.pem")
    host     = aws_instance.example.public_ip
  }
 provisioner "remote-exec" {
    inline = [
      "sudo yum install -y amazon-efs-utils",
      "sudo yum -y install wget",
      "sudo pip install botocore",
      "sudo service nfs start",
      "mkdir efs",
      "sudo mount -t efs -o tls ${module.efs.id}:/ efs"
    ]
  }
}


module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "my-s3-bucketfdgy534874892"
  acl    = "private"
}

resource "aws_glacier_vault" "my_archive" {
  name = "Compliance2021"
}