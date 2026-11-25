resource "aws_sns_topic" "regional" {
  kms_master_key_id = module.alarm_key[each.key].arn
  for_each          = setsubtract(var.regions, toset(keys(var.regional_alert_topics)))
  region            = each.value
  name              = "baseline-forward-health"
}
resource "aws_sns_topic_policy" "alarms" {
  for_each = aws_sns_topic.regional
  region   = each.key
  arn      = each.value.arn
  policy   = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Principal = { Service = "cloudwatch.amazonaws.com" }, Action = "sns:Publish", Resource = each.value.arn, Condition = { StringEquals = { "aws:SourceAccount" = var.account_id }, ArnLike = { "aws:SourceArn" = "arn:aws:cloudwatch:${each.key}:${var.account_id}:alarm:baseline-forward-*" } } }] })
}
resource "aws_sns_topic_subscription" "operator" {
  for_each  = aws_sns_topic.regional
  region    = each.key
  topic_arn = each.value.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
module "sensor" {
  for_each                 = var.regions
  source                   = "../../terraform/modules/regional-sensor"
  guardduty_features       = var.guardduty_features
  region                   = each.value
  bus_arn                  = var.central_bus_arn
  account_id               = var.account_id
  alert_topic              = try(var.regional_alert_topics[each.key], aws_sns_topic.regional[each.key].arn)
  manage_guardduty         = var.manage_guardduty
  manage_cspm              = var.manage_cspm
  manage_hub_v2            = var.manage_hub_v2
  enable_external_analyzer = var.enable_external_analyzer
}
module "bpa" {
  count  = var.manage_account_bpa ? 1 : 0
  source = "../../terraform/modules/s3-account-baseline"
}
resource "aws_iam_account_password_policy" "local" {
  count                          = var.manage_password_policy ? 1 : 0
  minimum_password_length        = 16
  require_numbers                = true
  require_symbols                = true
  allow_users_to_change_password = true
  password_reuse_prevention      = 24
}

module "alarm_key" {
  for_each   = setsubtract(var.regions, toset(keys(var.regional_alert_topics)))
  source     = "../../terraform/modules/alarm-key"
  account_id = var.account_id
  region     = each.key
  topic_name = "baseline-forward-health"
}
