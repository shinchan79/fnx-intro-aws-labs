resource "aws_ssm_patch_baseline" "test-baseline" {
  name             = "test-amazon-linux"
  description      = "Approves all Amazon Linux operating system patches that are classified as Security, Bugfix or Recommended"
  operating_system = "AMAZON_LINUX"

  global_filter {
    key = "CLASSIFICATION"
    values = [
      "Security",
      "Bugfix",
      "Recommended"
    ]
  }

  approval_rule {
    approve_after_days = 0

    patch_filter {
      key = "CLASSIFICATION"
      values = [
        "Security",
        "Bugfix",
        "Recommended"
      ]
    }
  }
}

resource "aws_ssm_patch_baseline" "prod-baseline" {
  name             = "prod-amazon-linux"
  description      = "Approves all Amazon Linux operating system patches that are classified as Security, Bugfix or Recommended"
  operating_system = "AMAZON_LINUX"

  global_filter {
    key = "CLASSIFICATION"
    values = [
      "Security",
      "Bugfix",
      "Recommended"
    ]
  }

  approval_rule {
    approve_after_days = 7

    patch_filter {
      key = "CLASSIFICATION"
      values = [
        "Security",
        "Bugfix",
        "Recommended"
      ]
    }
  }
}

# Map patch baselines to instances
resource "aws_ssm_patch_group" "test-patchgroup" {
  baseline_id = aws_ssm_patch_baseline.test-baseline.id
  patch_group = "test-amazon-linux"
}

resource "aws_ssm_patch_group" "prod-patchgroup" {
  baseline_id = aws_ssm_patch_baseline.prod-baseline.id
  patch_group = "prod-amazon-linux"
}
