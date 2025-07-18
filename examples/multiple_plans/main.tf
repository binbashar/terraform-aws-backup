# AWS SNS Topic
resource "aws_sns_topic" "backup_vault_notifications" {
  name = "backup-vault-events"
}

# AWS Backup
module "aws_backup_example" {
  source = "../.."

  # Vault
  vault_name = "vault-1"

  # Vault lock configuration
  min_retention_days = 7
  max_retention_days = 120

  # Multiple plans
  plans = {
    # First plan for daily backups
    daily = {
      name = "daily-backup-plan"
      rules = [
        {
          name              = "daily-rule"
          schedule          = "cron(0 12 * * ? *)"
          start_window      = 120
          completion_window = 360
          lifecycle = {
            delete_after = 30
          }
          recovery_point_tags = {
            Environment = "prod"
            Frequency   = "daily"
          }
        }
      ]
      selections = {
        prod_databases = {
          resources = [
            "arn:aws:dynamodb:us-east-1:123456789101:table/mydynamodb-table1"
          ]
          selection_tags = [
            {
              type  = "STRINGEQUALS"
              key   = "Environment"
              value = "prod"
            }
          ]
        }
      }
    },
    # Second plan for weekly backups
    weekly = {
      name = "weekly-backup-plan"
      rules = [
        {
          name              = "weekly-rule"
          schedule          = "cron(0 0 ? * 1 *)" # Run every Sunday at midnight
          start_window      = 120
          completion_window = 480
          lifecycle = {
            cold_storage_after = 30
            delete_after       = 120
          }
          recovery_point_tags = {
            Environment = "prod"
            Frequency   = "weekly"
          }
        }
      ]
      selections = {
        all_databases = {
          resources = [
            "arn:aws:dynamodb:us-east-1:123456789101:table/mydynamodb-table1",
            "arn:aws:dynamodb:us-east-1:123456789101:table/mydynamodb-table2"
          ]
        }
      }
    },
    # Third plan for monthly backups with cross-region copy
    monthly = {
      name = "monthly-backup-plan"
      rules = [
        {
          name              = "monthly-rule"
          schedule          = "cron(0 0 1 * ? *)" # Run at midnight on the first day of every month
          start_window      = 120
          completion_window = 720
          lifecycle = {
            cold_storage_after = 90
            delete_after       = 365
          }
          copy_actions = [
            {
              destination_vault_arn = "arn:aws:backup:us-west-2:123456789101:backup-vault:Default"
              lifecycle = {
                cold_storage_after = 90
                delete_after       = 365
              }
            }
          ]
          recovery_point_tags = {
            Environment = "prod"
            Frequency   = "monthly"
          }
        }
      ]
      selections = {
        critical_databases = {
          resources = [
            "arn:aws:dynamodb:us-east-1:123456789101:table/mydynamodb-table1"
          ]
          selection_tags = [
            {
              type  = "STRINGEQUALS"
              key   = "Criticality"
              value = "high"
            }
          ]
        }
      }
    }
  }

  # Tags
  tags = {
    Owner       = "backup team"
    Environment = "prod"
    Terraform   = true
  }
}