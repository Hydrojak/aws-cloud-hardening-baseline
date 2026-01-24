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
}

module "s3_guardrails" {
  source                    = "./modules/s3-guardrails"
  target_type               = var.guardrails_target_type
  target_iam_principal_name = var.guardrails_target_name
}

# V2.1 - Detection + Logging
module "alerting_cloudwatch" {
  source         = "./modules/alerting-cloudwatch"
  retention_days = var.cw_log_retention_days
  kms_key_arn    = var.cw_log_kms_key_arn
}

module "detection_eventbridge" {
  source        = "./modules/detection-eventbridge"
  log_group_arn = module.alerting_cloudwatch.log_group_arn
}

# V2.2 - Alerting (Alarms)
module "alerting_sns" {
  source     = "./modules/alerting-sns"
  topic_name = var.sns_topic_name
  kms_key_arn = var.sns_kms_key_arn

  email_subscriptions = var.sns_email == null ? [] : [var.sns_email]
}

module "alerting_alarms" {
  source         = "./modules/alerting-alarms"
  log_group_name = module.alerting_cloudwatch.log_group_name
  sns_topic_arn  = module.alerting_sns.topic_arn
}
