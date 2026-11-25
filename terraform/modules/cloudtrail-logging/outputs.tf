output "log_bucket_name" {
  value       = aws_s3_bucket.trail_logs.bucket
  description = "S3 bucket storing CloudTrail logs"
}

output "trail_name" {
  value       = try(aws_cloudtrail.baseline[0].name, null)
  description = "CloudTrail trail name"
}
