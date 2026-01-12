module "iam_baseline" {
  source = "./modules/iam-baseline"
}

module "cloudtrail_logging" {
  source          = "./modules/cloudtrail-logging"
  log_bucket_name = "hydrojak-baseline-logs-12345"
  trail_name      = "baseline-cloudtrail"
}
