mock_provider "aws" {
  mock_data "aws_partition" {
    defaults = { partition = "aws" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
}

variables {
  account_id            = "222222222222"
  management_account_id = "111111111111"
  organization_id       = "o-example12345"
  bucket_name           = "example-v3-archive"
}
run "separate_bucket" {
  command = plan

  assert {
    condition     = module.archive.trail_name == null && var.account_id != var.management_account_id
    error_message = "Failed contract separate_bucket."
  }
}
run "reject_shared_archive_account" {
  command = plan
  variables { account_id = "111111111111" }
  expect_failures = [terraform_data.separation]
}
