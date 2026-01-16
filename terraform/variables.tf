variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "tags" {
  description = "Tags applied to resources through provider default_tags"
  type        = map(string)
  default     = {}
}

# ---------------- CloudTrail ----------------

variable "cloudtrail_log_bucket_name" {
  description = "S3 bucket name for CloudTrail logs (must be globally unique)"
  type        = string
}

variable "cloudtrail_trail_name" {
  description = "CloudTrail trail name"
  type        = string
  default     = "baseline-cloudtrail"
}

variable "cloudtrail_is_multi_region" {
  description = "Enable multi-region CloudTrail (recommended true for hardening)"
  type        = bool
  default     = true
}

variable "cloudtrail_force_destroy_bucket" {
  description = "Allow destroying the log bucket even if it contains objects (LAB ONLY)"
  type        = bool
  default     = false
}

variable "cloudtrail_kms_key_arn" {
  description = "Optional KMS key ARN for CloudTrail S3 log encryption (null = SSE-S3)"
  type        = string
  default     = null
}

variable "cloudtrail_retention_days" {
  description = "Optional S3 expiration (days) for CloudTrail logs (0 disables expiration)"
  type        = number
  default     = 0
}

# ---------------- S3 Guardrails ----------------

variable "guardrails_target_type" {
  description = "IAM principal type to attach the guardrails to ('user' or 'role')"
  type        = string
  default     = "user"

  validation {
    condition     = contains(["user", "role"], var.guardrails_target_type)
    error_message = "guardrails_target_type must be 'user' or 'role'."
  }
}

variable "guardrails_target_name" {
  description = "IAM principal name (user or role) to attach S3 guardrails"
  type        = string
}

# ---------------- Detection / Alerting ----------------

variable "cw_log_retention_days" {
  description = "Retention (days) for detection CloudWatch Log Group"
  type        = number
  default     = 30
}

variable "cw_log_kms_key_arn" {
  description = "Optional KMS key ARN for encrypting detection CloudWatch Log Group"
  type        = string
  default     = null
}

variable "alarm_sns_topic_arn" {
  description = "Optional SNS topic ARN to notify on alarms (null disables actions)"
  type        = string
  default     = null
}
