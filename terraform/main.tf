module "iam_baseline" {
  source = "./modules/iam-baseline"
}

module "cloudtrail_logging" {
  source          = "./modules/cloudtrail-logging"
  log_bucket_name = "hydrojak-baseline-logs-12345"
  trail_name      = "baseline-cloudtrail"
}

module "s3_guardrails" {
  source                    = "./modules/s3-guardrails"
  target_type               = "user"
  target_iam_principal_name = "terraform-admin"
}
# V2.1 - Detection + Logging
module "alerting_cloudwatch" {
  source         = "./modules/alerting-cloudwatch"
  retention_days = 7
}

module "detection_eventbridge" {
  source        = "./modules/detection-eventbridge"
  log_group_arn = module.alerting_cloudwatch.log_group_arn
}

# V2.2 - Alerting (Alarms)
module "alerting_alarms" {
  source         = "./modules/alerting-alarms"
  log_group_name = module.alerting_cloudwatch.log_group_name
}
