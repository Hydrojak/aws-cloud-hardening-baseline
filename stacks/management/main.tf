data "aws_organizations_organization" "current" {}
resource "aws_cloudtrail" "organization" {
  name                          = var.trail_name
  s3_bucket_name                = var.bucket_name
  include_global_service_events = true
  is_multi_region_trail         = true
  is_organization_trail         = true
  enable_log_file_validation    = true
  enable_logging                = true
  kms_key_id                    = var.kms_key_arn
  event_selector {
    include_management_events = true
    read_write_type           = "All"
  }
  lifecycle {
    prevent_destroy = true
    precondition {
      condition     = var.account_id == data.aws_organizations_organization.current.master_account_id && var.organization_id == data.aws_organizations_organization.current.id && var.account_id != var.archive_account_id && startswith(var.kms_key_arn, "arn:aws:kms:${var.home_region}:${var.archive_account_id}:key/")
      error_message = "Verify the organization, management account and archive."
    }
  }
}
module "notifications" {
  kms_key_arn         = module.alarm_key.arn
  source              = "../../terraform/modules/alerting-sns"
  topic_name          = "baseline-trail-health"
  email_subscriptions = [var.alert_email]
}
module "monitor" {
  source          = "../../terraform/modules/remediation-cloudtrail"
  trail_name      = aws_cloudtrail.organization.name
  home_region     = var.home_region
  log_bucket_name = var.bucket_name
  kms_key_arn     = var.kms_key_arn
  org_trail       = true
  repair          = var.repair
  function_name   = "baseline-organization-trail-health"
  sns_topic_arn   = module.notifications.topic_arn
}
module "pilot_guardrail" {
  count                 = var.apply_scp ? 1 : 0
  source                = "../../terraform/modules/organizations-scp"
  target_id             = var.pilot_ou
  exempt_principal_arns = var.exception_role_arns
  archive_bucket_arn    = "arn:aws:s3:::${var.bucket_name}"
}
resource "aws_organizations_policy" "s3" {
  count   = var.apply_s3_policy ? 1 : 0
  name    = "baseline-pilot-block-public-s3"
  type    = "S3_POLICY"
  content = jsonencode({ s3_attributes = { public_access_block_configuration = { "@@assign" = "all" } } })
}
resource "aws_organizations_policy_attachment" "s3" {
  count     = var.apply_s3_policy ? 1 : 0
  target_id = var.pilot_ou
  policy_id = aws_organizations_policy.s3[0].id
}
output "trail_arn" { value = aws_cloudtrail.organization.arn }
resource "aws_budgets_budget" "monthly" {
  count        = var.monthly_budget_usd == null ? 0 : 1
  name         = "baseline-organization-monthly"
  budget_type  = "COST"
  time_unit    = "MONTHLY"
  limit_amount = tostring(var.monthly_budget_usd)
  limit_unit   = "USD"
  notification {
    comparison_operator        = "GREATER_THAN"
    notification_type          = "ACTUAL"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    subscriber_email_addresses = [var.alert_email]
  }
}

module "alarm_key" {
  source     = "../../terraform/modules/alarm-key"
  account_id = var.account_id
  region     = var.home_region
  topic_name = "baseline-trail-health"
}
