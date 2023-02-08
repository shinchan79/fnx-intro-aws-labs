provider "aws" {
  region     = "ap-northeast-1"
}

provider "aws" {
  alias  = "peer"
  region = "us-east-1"
  profile = "yentrinh-cloud"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "lab4-vpc"
  cidr = "192.168.0.0/16"

  azs             = ["ap-northeast-1a", "ap-northeast-1c"]
  private_subnets = ["192.168.0.0/18", "192.168.64.0/18"]
  public_subnets  = ["192.168.128.0/18", "192.168.192.0/18"]
}

module "peer" {
  providers = { aws = aws.peer }
  source = "terraform-aws-modules/vpc/aws"

  name = "lab4-vpc2"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1c"]
  private_subnets = ["10.0.0.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.1.0/24", "10.0.3.0/24"]
}

data "aws_caller_identity" "peer" {
  provider = aws.peer
}

# Requester's side of the connection.
resource "aws_vpc_peering_connection" "peer" {
  vpc_id        = module.vpc.vpc_id
  peer_vpc_id   = module.peer.vpc_id
  peer_owner_id = data.aws_caller_identity.peer.account_id
  peer_region   = "us-east-1"
  auto_accept   = false

  tags = {
    Side = "Requester"
  }
}

resource "aws_route" "main" {
  route_table_id            = module.vpc.default_route_table_id
  destination_cidr_block    = module.peer.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

# Accepter's side of the connection.
resource "aws_vpc_peering_connection_accepter" "peer" {
  provider                  = aws.peer
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  auto_accept               = true

  tags = {
    Side = "Accepter"
  }
}

# Routes for accepter 
resource "aws_route" "peer_route" {
  provider                  = aws.peer
  route_table_id            = module.peer.default_route_table_id
  destination_cidr_block    = module.vpc.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}


resource "aws_s3_bucket" "b" {
  bucket = "mybucketfgdhgtrwrhu4u48"
  force_destroy = true
}

resource "aws_s3_bucket_acl" "b_acl" {
  bucket = aws_s3_bucket.b.id
  acl    = "private"
}

resource "aws_s3_object" "object" {
  bucket = aws_s3_bucket_acl.b_acl.bucket
  key    = "vpc.png"
  source = "vpc.png"
  content_type = "image/png"
}

locals {
  s3_origin_id = "myS3Origin"
}


resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  bucket = aws_s3_bucket.b.id
  policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": {
        "Sid": "AllowCloudFrontServicePrincipalReadOnly",
        "Effect": "Allow",
        "Principal": {
            "Service": "cloudfront.amazonaws.com"
        },
        "Action": "s3:GetObject",
        "Resource": "${aws_s3_bucket.b.arn}/*",
        "Condition": {
            "StringEquals": {
                "AWS:SourceArn": "${aws_cloudfront_distribution.s3_distribution.arn}"
            }
        }
    }
}
  EOF
}


resource "aws_cloudfront_origin_access_control" "example" {
  name                              = "example"
  description                       = "Example Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.b.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.example.id
    origin_id                = local.s3_origin_id
  }

  enabled             = true
  comment             = "demo clf distribution"
  #default_root_object = "vpc.png"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}


output "dns_clf" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}