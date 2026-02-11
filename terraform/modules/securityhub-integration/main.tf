locals {
  alarm_actions = var.sns_topic_arn == null ? [] : [var.sns_topic_arn]
  ok_actions    = var.sns_topic_arn == null ? [] : [var.sns_topic_arn]

  # EventBridge filter object
  findings_filter = merge(
    {
      RecordState = var.record_states
      Severity    = { Label = var.severity_labels }
    },
      length(var.workflow_states) > 0 ? { Workflow = { Status = var.workflow_states } } : {}
  )

  # CloudWatch Logs metric filter string
  severity_expr = join(" || ", [
    for l in var.severity_labels : "$.detail.findings[*].Severity.Label = \"${l}\""
  ])

  record_expr = join(" || ", [
    for r in var.record_states : "$.detail.findings[*].RecordState = \"${r}\""
  ])

  workflow_expr = length(var.workflow_states) > 0
    ? " && (" + join(" || ", [for s in var.workflow_states : "$.detail.findings[*].Workflow.Status = \"${s}\""]) + ")"
    : ""

  metric_filter_pattern =
  "{ ($.source = \"aws.securityhub\") && ($.detail-type = \"Security Hub Findings - Imported\")"
  + " && (" + local.severity_expr + ")"
  + " && (" + local.record_expr + ")"
  + local.workflow_expr
  + " }"
}


resource "aws_securityhub_account" "this" {
count = var.manage_securityhub ? 1 : 0
}

resource "aws_cloudwatch_event_rule" "securityhub_findings" {
name = "${var.prefix}-securityhub-findings"

event_pattern = jsonencode({
"source": ["aws.securityhub"],
"detail-type": ["Security Hub Findings - Imported"],
"detail": { "findings": local.findings_filter }
})
}

resource "aws_cloudwatch_event_target" "to_logs" {
rule      = aws_cloudwatch_event_rule.securityhub_findings.name
target_id = "cwlogs"
arn       = var.log_group_arn
}

resource "aws_cloudwatch_log_metric_filter" "securityhub_high" {
name           = "detect-securityhub-high"
log_group_name = var.log_group_name
pattern        = local.metric_filter_pattern

metric_transformation {
name      = "SecurityHubHighSeverity"
namespace = var.namespace
value     = "1"
}
}

resource "aws_cloudwatch_metric_alarm" "securityhub_high" {
alarm_name        = "ALERT-SecurityHub-High-Severity"
comparison_operator = "GreaterThanOrEqualToThreshold"
evaluation_periods  = 1
period              = var.period_seconds
threshold           = var.threshold
statistic           = "Sum"

namespace   = var.namespace
metric_name = aws_cloudwatch_log_metric_filter.securityhub_high.metric_transformation[0].name

treat_missing_data = "notBreaching"
alarm_actions      = local.alarm_actions
ok_actions         = local.ok_actions
}
