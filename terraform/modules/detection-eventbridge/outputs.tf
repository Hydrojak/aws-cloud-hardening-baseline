output "role_name" {
  description = "IAM role used by EventBridge to write to CloudWatch Logs"
  value       = aws_iam_role.eventbridge_to_cwlogs.name
}

output "rule_names" {
  description = "Detection rule names"
  value = [
    aws_cloudwatch_event_rule.cloudtrail_tampering.name,
    aws_cloudwatch_event_rule.iam_policy_changes.name,
    aws_cloudwatch_event_rule.credential_creation.name,
    aws_cloudwatch_event_rule.s3_exposure_changes.name
  ]
}
