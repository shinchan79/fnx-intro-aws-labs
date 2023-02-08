module "store_write" {
  source  = "cloudposse/ssm-parameter-store/aws"

  parameter_write = [
    {
      name        = "/my-app/dev/db-url"
      value       = "dev.database.nhutpm.com:3306"
      type        = "String"
      description = "Production database master url"
    },
    {
      name        = "/my-app/dev/db-password"
      value       = "password123"
      type        = "SecureString"
      description = "Production database master password"
    }
  ]

  tags = {
    ManagedBy = "Terraform"
  }
}

#  aws ssm get-parameters --names /my-app/dev/db-password /my-app/dev/db-url
# aws ssm get-parameters --names /my-app/dev/db-password /my-app/dev/db-url --with-decryption