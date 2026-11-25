mock_provider "aws" {
  mock_data "aws_partition" {
    defaults = { partition = "aws" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
}

variables {
  account_id      = "444444444444"
  central_bus_arn = "arn:aws:events:eu-west-1:333333333333:event-bus/baseline-security"
  alert_email     = "ops@example.org"
}
run "two_regions" {
  command = plan

  assert {
    condition     = contains(keys(module.sensor), "us-east-1") && contains(keys(module.sensor), "eu-west-1") && length(aws_sns_topic_subscription.operator) == 2
    error_message = "Failed contract two_regions."
  }
}
run "reject_missing_global_region" {
  command = plan
  variables { regions = ["eu-west-1"] }
  expect_failures = [var.regions]
}
run "paid_profiles_explicit" {
  command = plan
  variables {
    manage_guardduty   = true
    manage_cspm        = true
    manage_hub_v2      = true
    guardduty_features = ["AI_PROTECTION", "RUNTIME_MONITORING"]
  }
  assert {
    condition     = length(module.sensor) == 2
    error_message = "Failed contract paid_profiles_explicit."
  }
}
