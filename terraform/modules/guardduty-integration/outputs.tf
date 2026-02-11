output "detector_id" {
  value = var.manage_detector ? aws_guardduty_detector.this[0].id : null
}
output "alarm_name" {
  value = aws_cloudwatch_metric_alarm.guardduty_high.alarm_name
}
