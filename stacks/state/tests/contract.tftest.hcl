mock_provider "aws" {
  mock_data "aws_partition" {
    defaults = { partition = "aws" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
}

variables {
  account_id  = "111111111111"
  bucket_name = "example-v3-state"
}
run "state_preserves_old_versions" {
  command = plan

  assert {
    condition     = aws_s3_bucket_versioning.state.versioning_configuration[0].status == "Enabled" && aws_s3_bucket_public_access_block.state.block_public_policy && !aws_s3_bucket.state.force_destroy
    error_message = "Failed contract state_preserves_old_versions."
  }
}
