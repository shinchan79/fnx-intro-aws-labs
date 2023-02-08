resource "aws_config_configuration_recorder" "foo" {
  name     = "example"
  role_arn = aws_iam_role.r.arn
}

resource "aws_iam_role" "r" {
  name = "my-awsconfig-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "p" {
  name = "my-awsconfig-policy"
  role = aws_iam_role.r.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Action": "config:Put*",
          "Effect": "Allow",
          "Resource": "*"

      },
      {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.foo.arn}",
        "${aws_s3_bucket.foo.arn}/*"
      ]
    }
  ]
}
POLICY
}

resource "aws_config_delivery_channel" "foo" {
  name           = "example"
  s3_bucket_name = aws_s3_bucket.foo.bucket
}

resource "aws_config_configuration_recorder_status" "foo" {
  name       = aws_config_configuration_recorder.foo.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.foo]
}


resource "aws_config_config_rule" "sg_ssh_restricted_check" {
  name        = "restricted-ssh"
  description = "A Config rule that checks whether security groups in use do not allow restricted incoming SSH traffic. This rule applies only to IPv4."

  source {
    owner             = "AWS"
    source_identifier = "INCOMING_SSH_DISABLED"
  }
  scope {
    compliance_resource_types = ["AWS::EC2::SecurityGroup"]
  }
}

resource "aws_config_config_rule" "sg_unrestricted_common_ports_check" {

  name             = "restricted-common-ports"
  description      = "A Config rule that checks whether security groups in use do not allow restricted incoming TCP traffic to the specified ports. This rule applies only to IPv4."
  input_parameters = "{\"blockedPort1\":\"20\",\"blockedPort2\":\"21\",\"blockedPort3\":\"3389\",\"blockedPort4\":\"3306\",\"blockedPort5\":\"4333\"}"

  source {
    owner             = "AWS"
    source_identifier = "RESTRICTED_INCOMING_TRAFFIC"
  }
  scope {
    compliance_resource_types = ["AWS::EC2::SecurityGroup"]
  }
}

resource "aws_config_config_rule" "ec2_stopped_instances_check" {

  name             = "ec2-stopped-instance"
  description      = "A Config rule that checks whether there are instances stopped for more than the allowed number of days. The instance is NON_COMPLIANT if the state of the ec2 instance has been stopped for longer than the allowed number of days."
  input_parameters = "{\"AllowedDays\":\"7\"}"

  source {
    owner             = "AWS"
    source_identifier = "EC2_STOPPED_INSTANCE"
  }
  scope {
    compliance_resource_types = []
  }
}

resource "aws_config_config_rule" "sg_open_to_specific_ports_only" {

  name        = "vpc-sg-open-only-to-authorized-ports"
  description = "A Config rule that checks whether the security group with 0.0.0.0/0 of any Amazon Virtual Private Cloud (Amazon VPCs) allows only specific inbound TCP or UDP traffic. The rule and any security group with inbound 0.0.0.0/0. is NON_COMPLIANT, if you do n..."

  source {
    owner             = "AWS"
    source_identifier = "VPC_SG_OPEN_ONLY_TO_AUTHORIZED_PORTS"
  }
  scope {
    compliance_resource_types = ["AWS::EC2::SecurityGroup"]
  }
}