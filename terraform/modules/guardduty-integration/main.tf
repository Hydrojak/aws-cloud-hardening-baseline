locals {
  alarm_actions = var.sns_topic_arn == null ? [] : [var.sns_topic_arn]
  ok_actions    = var.sns_topic_arn == null ? [] : [var.sns_topic_arn]
}

resource "aws_guardduty_detector" "this" {
  count  = var.manage_detector ? 1 : 0
  enable = true
}

resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name = "${var.prefix}-guardduty-findings"

  event_pattern = jsonencode({
    "detail-type": ["GuardDuty Finding"],
    "source": ["aws.guardduty"],
    "detail": {
      "severity": [{ "numeric": [">=", var.severity_min] }]
    }
  })
}

resource "aws_cloudwatch_event_target" "to_logs" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "cwlogs"
  arn       = var.log_group_arn
}

resource "aws_cloudwatch_log_metric_filter" "guardduty_high" {
  name           = "detect-guardduty-high"
  log_group_name = var.log_group_name
  pattern        = "{ ($.source = \"aws.guardduty\") && ($.detail-type = \"GuardDuty Finding\") && ($.detail.severity >= ${var.severity_min}) }"

  metric_transformation {
    name      = "GuardDutyHighSeverity"
    namespace = var.namespace
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "guardduty_high" {
  alarm_name        = "ALERT-GuardDuty-High-Severity"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  period              = var.period_seconds
  threshold           = var.threshold
  statistic           = "Sum"

  namespace   = var.namespace
  metric_name = aws_cloudwatch_log_metric_filter.guardduty_high.metric_transformation[0].name

  treat_missing_data = "notBreaching"
  alarm_actions      = local.alarm_actions
  ok_actions         = local.ok_actions
}
