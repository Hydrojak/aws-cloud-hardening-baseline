output "policy_arn" {
  description = "ARN of the S3 guardrails policy"
  value       = aws_iam_policy.s3_guardrails.arn
}
