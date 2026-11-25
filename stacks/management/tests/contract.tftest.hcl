mock_provider "aws" {
  mock_data "aws_partition" {
    defaults = { partition = "aws" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
  mock_data "aws_organizations_organization" {
    defaults = { master_account_id = "111111111111", id = "o-example12345" }
  }
}
mock_provider "archive" {}
variables {
  account_id         = "111111111111"
  organization_id    = "o-example12345"
  kms_key_arn        = "arn:aws:kms:eu-west-1:222222222222:key/00000000-1111-2222-3333-444444444444"
  archive_account_id = "222222222222"
  bucket_name        = "example-v3-archive"
  alert_email        = "ops@example.org"
  pilot_ou           = "ou-abcd-example123"
}
run "org_trail_checks" {
  command = plan

  assert {
    condition     = aws_cloudtrail.organization.is_multi_region_trail && aws_cloudtrail.organization.is_organization_trail && aws_cloudtrail.organization.enable_log_file_validation && aws_cloudtrail.organization.enable_logging && length(module.pilot_guardrail) == 0
    error_message = "Failed contract org_trail_checks."
  }
}
run "pilot_only" {
  command = plan
  variables {
    apply_s3_policy = true
    apply_scp       = true
  }
  assert {
    condition     = aws_organizations_policy_attachment.s3[0].target_id == var.pilot_ou && jsondecode(aws_organizations_policy.s3[0].content).s3_attributes.public_access_block_configuration["@@assign"] == "all"
    error_message = "Failed contract pilot_only."
  }
}
