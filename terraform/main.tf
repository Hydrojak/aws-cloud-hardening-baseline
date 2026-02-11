module "iam_baseline" {
  source = "./modules/iam-baseline"
}

module "cloudtrail_logging" {
  source                = "./modules/cloudtrail-logging"
  log_bucket_name       = var.cloudtrail_log_bucket_name
  trail_name            = var.cloudtrail_trail_name
  is_multi_region_trail = var.cloudtrail_is_multi_region
  force_destroy_bucket  = var.cloudtrail_force_destroy_bucket
  kms_key_arn           = var.cloudtrail_kms_key_arn
  retention_days        = var.cloudtrail_retention_days

  # Roadmap: stricter bucket policy conditions + org-level trail support
  trail_home_region             = var.aws_region
  strict_trail_source_arn       = var.cloudtrail_strict_trail_source_arn
  allow_organization_log_writes = var.cloudtrail_allow_organization_log_writes
  is_organization_trail         = var.cloudtrail_is_organization_trail

  enable_s3_data_events            = var.cloudtrail_enable_s3_data_events
  s3_data_event_bucket_arns        = var.cloudtrail_s3_data_event_bucket_arns
  enable_lambda_data_events        = var.cloudtrail_enable_lambda_data_events
  lambda_data_event_function_arns  = var.cloudtrail_lambda_data_event_function_arns
  data_events_read_write_type      = var.cloudtrail_data_events_read_write_type

}

module "s3_account_baseline" {
  source = "./modules/s3-account-baseline"
}


module "s3_guardrails" {
  source = "./modules/s3-guardrails"

  target_type               = var.guardrails_target_type
  target_iam_principal_name = var.guardrails_target_name

  enable_attachment = var.enable_guardrails_attachment
}




# V2.1 - Detection + Logging
module "alerting_cloudwatch" {
  source         = "./modules/alerting-cloudwatch"
  retention_days = var.cw_log_retention_days
  kms_key_arn    = var.cw_log_kms_key_arn
}


# V2.2 - Alerting (Alarms)
module "alerting_sns" {
  count     = var.create_sns_topic ? 1 : 0
  source    = "./modules/alerting-sns"
  topic_name = var.sns_topic_name
  kms_key_arn = var.sns_kms_key_arn

  email_subscriptions = var.sns_email == null ? [] : [var.sns_email]
}

locals {
  effective_sns_topic_arn = var.create_sns_topic ? module.alerting_sns[0].topic_arn : var.alarm_sns_topic_arn
}

module "alerting_alarms" {
  source         = "./modules/alerting-alarms"
  log_group_name = module.alerting_cloudwatch.log_group_name
  sns_topic_arn  = local.effective_sns_topic_arn
}



# Roadmap: Optional automated remediation (Lambda)
module "remediation_cloudtrail" {
  count  = var.enable_cloudtrail_auto_remediation ? 1 : 0
  source = "./modules/remediation-cloudtrail"

  trail_name            = var.cloudtrail_trail_name
  home_region           = var.aws_region
  is_multi_region_trail = var.cloudtrail_is_multi_region

  log_bucket_name = var.cloudtrail_log_bucket_name
  kms_key_arn     = var.cloudtrail_kms_key_arn

  log_retention_days = var.remediation_log_retention_days
  s3_data_event_bucket_arns       = var.cloudtrail_s3_data_event_bucket_arns
  lambda_data_event_function_arns = var.cloudtrail_lambda_data_event_function_arns
  data_events_read_write_type     = var.cloudtrail_data_events_read_write_type

}

# Roadmap: Organization-level deployment (SCPs)
module "organizations_scp" {
  count  = var.enable_org_scp ? 1 : 0
  source = "./modules/organizations-scp"

  target_id             = var.org_scp_target_id
  policy_name           = var.org_scp_name
  exempt_principal_arns = var.org_scp_exempt_principal_arns
}

module "detection_eventbridge" {
  source        = "./modules/detection-eventbridge"
  log_group_arn = module.alerting_cloudwatch.log_group_arn

  cloudtrail_remediation_lambda_arn = var.enable_cloudtrail_auto_remediation ? module.remediation_cloudtrail[0].lambda_arn : null
}
module "guardduty_integration" {
  count  = var.enable_guardduty_integration ? 1 : 0
  source = "./modules/guardduty-integration"

  prefix       = var.prefix
  severity_min = var.guardduty_severity_min

  log_group_arn  = module.alerting_cloudwatch.log_group_arn
  log_group_name = module.alerting_cloudwatch.log_group_name

  sns_topic_arn = local.effective_sns_topic_arn
}

module "securityhub_integration" {
  count  = var.enable_securityhub_integration ? 1 : 0
  source = "./modules/securityhub-integration"

  prefix          = var.prefix
  severity_labels = var.securityhub_severity_labels
  record_states   = var.securityhub_record_states
  workflow_states = var.securityhub_workflow_states

  log_group_arn  = module.alerting_cloudwatch.log_group_arn
  log_group_name = module.alerting_cloudwatch.log_group_name

  sns_topic_arn = local.effective_sns_topic_arn
}

