variable "region" { type = string }
variable "bus_arn" { type = string }
variable "account_id" { type = string }
variable "alert_topic" { type = string }
variable "manage_guardduty" { type = bool }
variable "manage_cspm" { type = bool }
variable "manage_hub_v2" { type = bool }
variable "enable_external_analyzer" { type = bool }
locals {
  patterns = { for f in fileset("${path.module}/../../../catalog", "*.json") : trimsuffix(f, ".json") => file("${path.module}/../../../catalog/${f}") }
}
resource "aws_cloudwatch_event_rule" "signal" {
  state         = each.key == "root-use" ? "ENABLED_WITH_ALL_CLOUDTRAIL_MANAGEMENT_EVENTS" : "ENABLED"
  for_each      = local.patterns
  region        = var.region
  name          = "baseline-forward-${each.key}"
  event_pattern = jsonencode(merge(jsondecode(each.value), { account = [var.account_id] }))
}
resource "aws_iam_role" "forward" {
  name               = "baseline-event-forward-${var.region}"
  assume_role_policy = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Principal = { Service = "events.amazonaws.com" }, Action = "sts:AssumeRole", Condition = { StringEquals = { "aws:SourceAccount" = var.account_id }, ArnEquals = { "aws:SourceArn" = [for r in aws_cloudwatch_event_rule.signal : r.arn] } } }] })
}
resource "aws_iam_role_policy" "forward" {
  role   = aws_iam_role.forward.id
  policy = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Action = "events:PutEvents", Resource = var.bus_arn }] })
}
module "failure" {
  source      = "../delivery-queue"
  region      = var.region
  name        = "baseline-forward"
  rule_arns   = [for r in aws_cloudwatch_event_rule.signal : r.arn]
  alert_topic = var.alert_topic
}
resource "aws_cloudwatch_event_target" "forward" {
  for_each  = aws_cloudwatch_event_rule.signal
  region    = var.region
  rule      = each.value.name
  target_id = "security"
  arn       = var.bus_arn
  role_arn  = aws_iam_role.forward.arn
  dead_letter_config { arn = module.failure.arn }
  retry_policy {
    maximum_event_age_in_seconds = 86400
    maximum_retry_attempts       = 185
  }
  depends_on = [aws_iam_role_policy.forward]
}
resource "aws_guardduty_detector" "managed" {
  count  = var.manage_guardduty ? 1 : 0
  region = var.region
  enable = true
}
resource "aws_securityhub_account" "cspm" {
  count  = var.manage_cspm ? 1 : 0
  region = var.region
}
resource "aws_securityhub_account_v2" "unified" {
  count  = var.manage_hub_v2 ? 1 : 0
  region = var.region
}
resource "aws_accessanalyzer_analyzer" "external" {
  count         = var.enable_external_analyzer ? 1 : 0
  region        = var.region
  type          = "ACCOUNT"
  analyzer_name = "baseline-external-access"
}
variable "guardduty_features" { type = set(string) }
data "aws_guardduty_detector" "existing" {
  count  = !var.manage_guardduty && length(var.guardduty_features) > 0 ? 1 : 0
  region = var.region
}
resource "aws_guardduty_detector_feature" "feature" {
  for_each    = var.guardduty_features
  region      = var.region
  detector_id = var.manage_guardduty ? aws_guardduty_detector.managed[0].id : data.aws_guardduty_detector.existing[0].id
  name        = each.key
  status      = "ENABLED"
}
