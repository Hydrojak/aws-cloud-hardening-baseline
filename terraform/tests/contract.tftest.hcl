mock_provider "aws" {
  mock_data "aws_partition" {
    defaults = { partition = "aws" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
}
mock_provider "archive" {}
variables {
  cloudtrail_log_bucket_name   = "example-v3-lab"
  guardrails_target_name       = "ExampleRole"
  enable_guardrails_attachment = false
  sns_email                    = "ops@example.org"
}
run "lab_safe_defaults" {
  command = plan

  assert {
    condition     = length(module.remediation_cloudtrail) == 0 && length(module.organizations_scp) == 0 && length(aws_cloudwatch_event_target.lab_relay) == 1
    error_message = "Failed contract lab_safe_defaults."
  }
}
run "first_plan_optional_features" {
  command = plan
  variables {
    enable_cloudtrail_auto_remediation = true
    enable_guardduty_integration       = true
    enable_securityhub_integration     = true
  }
  assert {
    condition     = length(module.remediation_cloudtrail) == 1 && length(module.guardduty_integration) == 1 && length(module.securityhub_integration) == 1
    error_message = "Failed contract first_plan_optional_features."
  }
}
