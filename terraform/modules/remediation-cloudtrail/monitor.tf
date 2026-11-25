data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
locals {
  trail_arn = "arn:${data.aws_partition.current.partition}:cloudtrail:${var.home_region}:${data.aws_caller_identity.current.account_id}:trail/${var.trail_name}"
  resources = concat(length(var.s3_data_event_bucket_arns) > 0 ? [{ Type = "AWS::S3::Object", Values = [for a in var.s3_data_event_bucket_arns : "${trimsuffix(a, "/")}/"] }] : [],
  length(var.lambda_data_event_function_arns) > 0 ? [{ Type = "AWS::Lambda::Function", Values = var.lambda_data_event_function_arns }] : [])
  selectors = concat([{ ReadWriteType = "All", IncludeManagementEvents = true }], length(local.resources) > 0 ? [{ ReadWriteType = var.data_events_read_write_type, IncludeManagementEvents = false, DataResources = local.resources }] : [])
  actions   = var.sns_topic_arn == null ? [] : [var.sns_topic_arn]
}
resource "aws_cloudwatch_event_rule" "check" {
  name                = "${var.function_name}-check"
  schedule_expression = "rate(5 minutes)"
}
resource "aws_lambda_permission" "timer" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.check.arn
}
resource "aws_cloudwatch_event_target" "check" {
  rule       = aws_cloudwatch_event_rule.check.name
  arn        = aws_lambda_function.this.arn
  depends_on = [aws_lambda_permission.timer]
}
resource "aws_cloudwatch_log_metric_filter" "health" {
  name           = "scheduled-success"
  log_group_name = aws_cloudwatch_log_group.lambda.name
  pattern        = "\"scheduled_check_completed\""
  metric_transformation {
    namespace = "Baseline/TrailHealth"
    name      = var.function_name
    value     = "1"
  }
}
resource "aws_cloudwatch_metric_alarm" "heartbeat" {
  alarm_name          = "${var.function_name}-heartbeat"
  namespace           = "Baseline/TrailHealth"
  metric_name         = var.function_name
  statistic           = "Sum"
  comparison_operator = "LessThanThreshold"
  threshold           = 1
  period              = 300
  evaluation_periods  = 3
  treat_missing_data  = "breaching"
  alarm_actions       = local.actions
}
resource "aws_cloudwatch_metric_alarm" "failure" {
  alarm_name          = "${var.function_name}-errors"
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  dimensions          = { FunctionName = aws_lambda_function.this.function_name }
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.actions
}
