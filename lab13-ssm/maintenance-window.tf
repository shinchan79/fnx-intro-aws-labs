# Test Maintenance Window
resource "aws_ssm_maintenance_window" "test-window" {
  name              = "test-patching"
  schedule          = "cron(0 0 6 ? * TUE *)" #3pm AEST in UTC
  duration          = 3
  cutoff            = 1
  schedule_timezone = "Etc/UTC"
  enabled           = true
}

resource "aws_ssm_maintenance_window_target" "test-window-targets" {
  window_id     = aws_ssm_maintenance_window.test-window.id
  name          = "amazon-linux-targets"
  resource_type = "RESOURCE_GROUP"

  targets {
    key    = "resource-groups:Name"
    values = ["test_servers"]
  }

  depends_on = [aws_ssm_maintenance_window.test-window]
}

resource "aws_ssm_maintenance_window_task" "test-window-task" {
  max_concurrency  = 50
  max_errors       = 100
  priority         = 1
  service_role_arn = aws_iam_role.ssm-patching-role.arn
  task_arn         = aws_ssm_document.ssm-document.arn
  task_type        = "AUTOMATION"
  window_id        = aws_ssm_maintenance_window.test-window.id

  targets {
    key    = "WindowTargetIds"
    values = ["${aws_ssm_maintenance_window_target.test-window-targets.id}"]
  }

  task_invocation_parameters {
    automation_parameters {
      document_version = "$LATEST"

      parameter {
        name   = "Instance"
        values = ["{{ RESOURCE_ID }}"]
      }

    }
  }
}

# Prod Maintenance Window
resource "aws_ssm_maintenance_window" "prod-window" {
  name              = "prod-patching"
  schedule          = "cron(0 0 6 ? * TUE *)" #3pm AEST in UTC
  duration          = 3
  cutoff            = 1
  schedule_timezone = "Etc/UTC"
  enabled           = true
}

resource "aws_ssm_maintenance_window_target" "prod-window-targets" {
  window_id     = aws_ssm_maintenance_window.prod-window.id
  name          = "amazon-linux-targets"
  resource_type = "RESOURCE_GROUP"

  targets {
    key    = "resource-groups:Name"
    values = ["prod_servers"]
  }

  depends_on = [aws_ssm_maintenance_window.prod-window]
}

resource "aws_ssm_maintenance_window_task" "prod-window-task" {
  max_concurrency  = 50
  max_errors       = 100
  priority         = 1
  service_role_arn = aws_iam_role.ssm-patching-role.arn
  task_arn         = aws_ssm_document.ssm-document.arn
  task_type        = "AUTOMATION"
  window_id        = aws_ssm_maintenance_window.prod-window.id

  targets {
    key    = "WindowTargetIds"
    values = ["${aws_ssm_maintenance_window_target.prod-window-targets.id}"]
  }

  task_invocation_parameters {
    automation_parameters {
      document_version = "$LATEST"

      parameter {
        name   = "Instance"
        values = ["{{ RESOURCE_ID }}"]
      }

    }
  }
}