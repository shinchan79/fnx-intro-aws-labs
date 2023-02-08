module "ec2" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  name = "windows-server"

  ami                    = "ami-05f53c2def3a51a08"
  instance_type          = "t2.micro"
  key_name               = "yen-key"
  monitoring             = true
  vpc_security_group_ids = ["sg-0b3f158f154d91301"]
  subnet_id              = "subnet-0a6b9af823267035e"

  root_block_device = [
    {
      encrypted   = true
      volume_type = "gp3"
      throughput  = 200
      volume_size = 50
    },
  ]
}

resource "aws_volume_attachment" "this" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.this.id
  instance_id = module.ec2.id
}

resource "aws_ebs_volume" "this" {
  availability_zone = "ap-northeast-1c"
  size              = 1
}