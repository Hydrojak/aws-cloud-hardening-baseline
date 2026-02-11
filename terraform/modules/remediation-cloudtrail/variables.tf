variable "trail_name" {
  description = "CloudTrail trail name to remediate"
  type        = string
}

variable "home_region" {
  description = "Home region of the CloudTrail trail"
  type        = string
}

variable "is_multi_region_trail" {
  description = "Expected multi-region setting (baseline)"
  type        = bool
  default     = true
}

variable "log_bucket_name" {
  description = "Expected S3 bucket name used by the trail (baseline)"
  type        = string
}

variable "kms_key_arn" {
  description = "Optional KMS key ARN to enforce on the trail (baseline)"
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "Retention (days) for the remediation Lambda log group"
  type        = number
  default     = 14
}

variable "function_name" {
  description = "Optional Lambda function name"
  type        = string
  default     = "baseline-cloudtrail-auto-remediation"
}
variable "s3_data_event_bucket_arns" {
  type        = list(string)
  default     = []
}

variable "lambda_data_event_function_arns" {
  type        = list(string)
  default     = []
}

variable "data_events_read_write_type" {
  type        = string
  default     = "All"
}
