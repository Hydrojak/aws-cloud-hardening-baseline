output "alarm_names" {
  description = "CloudWatch alarm names created by V2.2"
  value = [
    aws_cloudwatch_metric_alarm.cloudtrail_tampering.alarm_name,
    aws_cloudwatch_metric_alarm.iam_policy_changes.alarm_name,
    aws_cloudwatch_metric_alarm.credential_creation.alarm_name,
    aws_cloudwatch_metric_alarm.s3_exposure.alarm_name
  ]
}
