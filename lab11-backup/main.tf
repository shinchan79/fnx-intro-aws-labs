provider "aws" {
  region = "us-east-1"
}

module "aws_backup_example" {

  source = "lgallard/backup/aws"

  # Vault
  vault_name = "vault-1"

  # Plan
  plan_name = "complete-plan"


  # Multiple rules using a list of maps
  rules = [
    {
      name                     = "rule-1"
      schedule                 = "cron(0 12 * * ? *)"
      target_vault_name        = null
      start_window             = 120
      completion_window        = 360
      enable_continuous_backup = true
      lifecycle = {
        cold_storage_after = 0
        delete_after       = 30
      },
      
      recovery_point_tags = {
        Environment = "production"
      }
    }
  ]

  # Multiple selections
  selections = [
    {
      name          = "selection-1"
      resources     = ["${aws_ebs_volume.example.arn}"]
      not_resources = []
      conditions = {
        string_equals = [
          {
            key   = "aws:ResourceTag/Owner"
            value = "devops"
          }
          ,
          {
            key   = "aws:ResourceTag/Environment"
            value = "production"
          }
        ]
      }
    },
  ]

  tags = {
    Owner       = "devops"
    Environment = "production"
    Terraform   = true
  }

}

resource "aws_ebs_volume" "example" {
  availability_zone = "us-east-1a"
  size              = 1

  tags = {
    Owner       = "devops"
    Environment = "production"
  }
}