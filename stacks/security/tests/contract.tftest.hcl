mock_provider "aws" {
  mock_data "aws_partition" {
    defaults = { partition = "aws" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
}

variables {
  account_id      = "333333333333"
  organization_id = "o-example12345"
  source_accounts = ["444444444444"]
  alert_email     = "ops@example.org"
}
run "all_categories_have_alerts" {
  command = plan

  assert {
    condition     = length(aws_cloudwatch_event_rule.signal) == 9 && length(aws_cloudwatch_event_target.logs) == 9 && length(aws_cloudwatch_metric_alarm.signal) == 9 && aws_cloudwatch_event_bus.security.name == "baseline-security"
    error_message = "Failed contract all_categories_have_alerts."
  }
}
