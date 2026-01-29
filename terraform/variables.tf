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

variable "sns_topic_name" {
  description = "SNS topic name for security alerts"
  type        = string
  default     = "cloud-hardening-alerts"
}

variable "sns_email" {
  description = "Email to receive SNS alerts (set to null to disable email subscription)"
  type        = string
  default     = null
}

variable "sns_kms_key_arn" {
  description = "Optional KMS key ARN for SNS encryption"
  type        = string
  default     = null
}
variable "alarm_sns_topic_arn" {
  description = "Optional existing SNS topic ARN to use for alarm notifications (used when create_sns_topic = false)"
  type        = string
  default     = null
}

variable "create_sns_topic" {
  description = "Whether to create an SNS topic for alarm notifications. If false, alarm_sns_topic_arn is used (and may be null to disable alarm actions)."
  type        = bool
  default     = true
}
variable "enable_guardrails_attachment" {
  description = "If true, attach the S3 guardrails policy to the target principal. If false, only create the policy."
  type        = bool
  default     = true
}

