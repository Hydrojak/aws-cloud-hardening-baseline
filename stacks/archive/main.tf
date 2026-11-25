module "archive" {
  source                = "../../terraform/modules/cloudtrail-logging"
  providers             = { aws = aws, aws.archive = aws }
  trail_owner_id        = var.management_account_id
  create_trail          = false
  is_organization_trail = true
  organization_id       = var.organization_id
  trail_home_region     = var.home_region
  trail_name            = var.trail_name
  log_bucket_name       = var.bucket_name
  use_kms               = true
  kms_key_arn           = local.archive_key_arn
  retention_days        = var.retention_days
  object_lock_days      = var.object_lock_days
  force_destroy_bucket  = false
}
resource "terraform_data" "separation" {
  lifecycle {
    precondition {
      condition     = var.account_id != var.management_account_id && var.retention_days >= var.object_lock_days && var.object_lock_days > 0
      error_message = "Use an independent archive account and positive retention, no longer than lifecycle expiration."
    }
  }
}
output "archive_bucket" { value = module.archive.log_bucket_name }
