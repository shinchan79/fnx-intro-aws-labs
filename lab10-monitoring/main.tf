provider "aws" {
  region = "ap-northeast-1"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "example" {
  ami = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  availability_zone = "ap-northeast-1a"
  
  lifecycle {
      ignore_changes = [ami]
    }
}

resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
     alarm_name                = "TerminateEC2OnHighCPU"
     comparison_operator       = "GreaterThanOrEqualToThreshold"
     evaluation_periods        = "1"
     metric_name               = "CPUUtilization"
     namespace                 = "AWS/EC2"
     period                    = "60" #seconds
     statistic                 = "Average"
     threshold                 = "95"
     alarm_description         = "This metric monitors ec2 cpu utilization"
     alarm_actions = ["arn:aws:automate:ap-northeast-1:ec2:terminate"]
     dimensions = {       
      InstanceId = aws_instance.example.id     
    }
}

#  aws cloudwatch set-alarm-state --alarm-name TerminateEC2OnHighCPU --state-value ALARM --state-reason "Testing"

resource "aws_cloudwatch_event_bus" "messenger" {
  name = "custom-bus"
}

resource "aws_cloudwatch_event_rule" "console" {
  name        = "DemoCodePipeline"

  event_pattern = <<EOF
{
  "source":["aws.codepipeline"],
  "detail-type": [
    "CodePipeline Pipeline Execution State Change"
  ]
}
EOF
}


data "aws_caller_identity" "current" {}

resource "aws_cloudtrail" "foobar" {
  name                          = "tf-trail-foobar"
  s3_bucket_name                = aws_s3_bucket.foo.id
  s3_key_prefix                 = "cloudtrail"
  include_global_service_events = false
  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.example.arn}:*"
  cloud_watch_logs_role_arn = aws_iam_role.cloudtrail-roles.arn
  depends_on = [
    aws_cloudwatch_log_group.example
  ]
}

resource "aws_s3_bucket" "foo" {
  bucket        = "tf-test-trailasf34t34g4e"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "foo" {
  bucket = aws_s3_bucket.foo.id
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "${aws_s3_bucket.foo.arn}"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "${aws_s3_bucket.foo.arn}/cloudtrail/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
POLICY
}

resource "aws_cloudwatch_log_group" "example" {
  name = "Example"
}
