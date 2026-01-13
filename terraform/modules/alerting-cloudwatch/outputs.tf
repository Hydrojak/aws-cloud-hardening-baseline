output "log_group_name" {
  description = "Detection log group name"
  value       = aws_cloudwatch_log_group.detections.name
}

output "log_group_arn" {
  description = "Detection log group ARN"
  value       = aws_cloudwatch_log_group.detections.arn
}
