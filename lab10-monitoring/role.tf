variable "cloudtrail_assume_role_policy_document" {
  type        = string
  description = "assume role policy document"
  default     = <<-EOF
   {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": "cloudtrail.amazonaws.com"
          },
          "Effect": "Allow"
        }
      ]
   }
  EOF
}
resource "aws_iam_role" "cloudtrail-roles" {
  name = "my-cloudtrail-role"
  assume_role_policy = var.cloudtrail_assume_role_policy_document
}
resource "aws_iam_policy" "cloudtrail-policy" {
  name        = "my-trail-policy-for-log-groups"
  description = "policy for trail to send events to cloudwatch log groups"  
  policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream"
            ],
            "Resource": [
              "${aws_cloudwatch_log_group.example.arn}:*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:PutLogEvents"
            ],
            "Resource": [
              "${aws_cloudwatch_log_group.example.arn}:*"
            ]
        }
      ]
    }
  EOF
}
resource "aws_iam_role_policy_attachment" "cloudtrail-roles-policies" {
  role       = aws_iam_role.cloudtrail-roles.name
  policy_arn = aws_iam_policy.cloudtrail-policy.arn
}