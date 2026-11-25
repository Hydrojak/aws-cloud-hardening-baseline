mock_provider "aws" {
  mock_data "aws_partition" {
    defaults = { partition = "aws" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
}

variables {
  account_id          = "111111111111"
  home_region         = "eu-west-1"
  instance_arn        = "arn:aws:sso:::instance/ssoins-1234567890123456"
  security_group_id   = "12345678-1234-1234-1234-123456789012"
  security_account_id = "333333333333"
}
run "short_federated_read_only_session" {
  command = plan

  assert {
    condition     = aws_ssoadmin_permission_set.investigator.session_duration == "PT2H" && aws_ssoadmin_account_assignment.investigators.target_id == var.security_account_id
    error_message = "Failed contract short_federated_read_only_session."
  }
}
