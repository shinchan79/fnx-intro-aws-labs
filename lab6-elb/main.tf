provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_ami_from_instance" "example" {
  name               = "WebServerAMI"
  source_instance_id = "i-0d2fba4b6ed1b67d3"
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 8.0"

  name = "LabELB"

  load_balancer_type = "application"

  vpc_id             = "vpc-0e002ea9920b93e82"
  subnets            = ["subnet-062b75d8e423b28c8", "subnet-0a6b9af823267035e"]
  security_groups    = ["sg-0b3f158f154d91301"]

  target_groups = [
    {
      name     = "LabGroup"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]
}

data "template_file" "this" {
  template =<<EOF
#!/bin/bash
yum update -y
yum install -y httpd.x86_64
systemctl start httpd
systemctl enable http
echo "$(curl http://169.254.169.254/latest/meta-data/local-ipv4)" > /var/www/html/index.html
EOF
}

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"

  # Autoscaling group
  name = "example-asg"

  min_size                  = 2
  max_size                  = 6
  desired_capacity          = 2
  wait_for_capacity_timeout = 0
  health_check_type         = "EC2"
  vpc_zone_identifier       = ["subnet-062b75d8e423b28c8", "subnet-0a6b9af823267035e"]

  initial_lifecycle_hooks = [
    {
      name                  = "ExampleStartupLifeCycleHook"
      default_result        = "CONTINUE"
      heartbeat_timeout     = 60
      lifecycle_transition  = "autoscaling:EC2_INSTANCE_LAUNCHING"
      notification_metadata = jsonencode({ "hello" = "world" })
    },
    {
      name                  = "ExampleTerminationLifeCycleHook"
      default_result        = "CONTINUE"
      heartbeat_timeout     = 180
      lifecycle_transition  = "autoscaling:EC2_INSTANCE_TERMINATING"
      notification_metadata = jsonencode({ "goodbye" = "world" })
    }
  ]

  user_data = "${base64encode(data.template_file.this.rendered)}"
  # Launch template
  launch_template_name        = "example-asg"
  launch_template_description = "Launch template example"
  update_default_version      = true

  image_id          = aws_ami_from_instance.example.id
  instance_type     = "t3.micro"
  ebs_optimized     = false
  enable_monitoring = false


  # IAM role & instance profile
  create_iam_instance_profile = true
  iam_role_name               = "example-asg-role"
  iam_role_path               = "/ec2/"
  iam_role_description        = "IAM role example"
  iam_role_tags = {
    CustomIamRole = "Yes"
  }
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  block_device_mappings = [
    {
      # Root volume
      device_name = "/dev/xvda"
      no_device   = 0
      ebs = {
        delete_on_termination = true
        encrypted             = true
        volume_size           = 20
        volume_type           = "gp2"
      }
    }
  ]

  credit_specification = {
    cpu_credits = "standard"
  }

  network_interfaces = [
    {
      delete_on_termination = true
      description           = "eth0"
      device_index          = 0
      security_groups       = ["sg-0b3f158f154d91301"]
    }
  ]

  placement = {
    availability_zone = "ap-northeast-1a"
  }

  target_group_arns = ["${module.alb.target_group_arns[0]}"]
}