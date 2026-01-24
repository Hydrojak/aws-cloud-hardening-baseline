# Root outputs (optional but useful)

output "cloudtrail_log_bucket_name" {
  description = "S3 bucket storing CloudTrail logs"
  value       = module.cloudtrail_logging.log_bucket_name
}

output "cloudtrail_trail_name" {
  description = "CloudTrail trail name"
  value       = module.cloudtrail_logging.trail_name
}

output "detections_log_group_name" {
  description = "CloudWatch Log Group receiving detection events"
  value       = module.alerting_cloudwatch.log_group_name
}

output "detections_log_group_arn" {
  description = "CloudWatch Log Group ARN receiving detection events"
  value       = module.alerting_cloudwatch.log_group_arn
}


output "alarm_names" {
  description = "CloudWatch alarm names created by V2.2"
  value       = module.alerting_alarms.alarm_names
}

output "s3_guardrails_policy_arn" {
  description = "ARN of the S3 guardrails policy"
  value       = module.s3_guardrails.policy_arn
}

output "access_analyzer_name" {
  description = "Name of the IAM Access Analyzer"
  value       = module.iam_baseline.access_analyzer_name
}
output "sns_topic_arn" {
  description = "SNS topic ARN for alarms"
  value       = module.alerting_sns.topic_arn
}
