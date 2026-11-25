locals {
  patterns = { for f in fileset("${path.module}/../../catalog", "*.json") : trimsuffix(f, ".json") => file("${path.module}/../../catalog/${f}") }
}
resource "aws_cloudwatch_event_bus" "security" { name = "baseline-security" }
resource "aws_cloudwatch_event_bus_policy" "ingress" {
  event_bus_name = aws_cloudwatch_event_bus.security.name
  policy         = module.ingress_policy.policy
}
module "logs" {
  source         = "../../terraform/modules/alerting-cloudwatch"
  log_group_name = "/aws/events/baseline-security"
  retention_days = var.retention_days
}
module "notifications" {
  kms_key_arn         = module.alarm_key.arn
  source              = "../../terraform/modules/alerting-sns"
  topic_name          = "baseline-security-alerts"
  email_subscriptions = [var.alert_email]
}
resource "aws_cloudwatch_event_rule" "signal" {
  state          = each.key == "root-use" ? "ENABLED_WITH_ALL_CLOUDTRAIL_MANAGEMENT_EVENTS" : "ENABLED"
  for_each       = local.patterns
  name           = "baseline-receive-${each.key}"
  event_bus_name = aws_cloudwatch_event_bus.security.name
  event_pattern  = jsonencode(merge(jsondecode(each.value), { account = sort(var.source_accounts) }))
}
module "failure" {
  source      = "../../terraform/modules/delivery-queue"
  region      = var.home_region
  name        = "baseline-central"
  rule_arns   = [for r in aws_cloudwatch_event_rule.signal : r.arn]
  alert_topic = module.notifications.topic_arn
}
resource "aws_cloudwatch_event_target" "logs" {
  for_each       = aws_cloudwatch_event_rule.signal
  event_bus_name = aws_cloudwatch_event_bus.security.name
  rule           = each.value.name
  target_id      = "evidence"
  arn            = module.logs.log_group_arn
  dead_letter_config { arn = module.failure.arn }
  depends_on = [module.logs]
}
resource "aws_cloudwatch_metric_alarm" "signal" {
  for_each            = aws_cloudwatch_event_rule.signal
  alarm_name          = "baseline-security-${each.key}"
  namespace           = "AWS/Events"
  metric_name         = "MatchedEvents"
  dimensions          = { EventBusName = aws_cloudwatch_event_bus.security.name, RuleName = each.value.name }
  period              = 60
  evaluation_periods  = 1
  statistic           = "Sum"
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [module.notifications.topic_arn]
}
output "bus_arn" { value = aws_cloudwatch_event_bus.security.arn }
output "alert_topic" { value = module.notifications.topic_arn }

module "ingress_policy" {
  source          = "../../terraform/modules/bus-policy"
  source_accounts = var.source_accounts
  organization_id = var.organization_id
  bus_arn         = aws_cloudwatch_event_bus.security.arn
}

module "alarm_key" {
  source     = "../../terraform/modules/alarm-key"
  account_id = var.account_id
  region     = var.home_region
  topic_name = "baseline-security-alerts"
}
