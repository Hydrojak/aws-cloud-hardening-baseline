variable "topic_name" {
  description = "SNS topic name"
  type        = string
  default     = "cloud-hardening-alerts"
}

variable "email_subscriptions" {
  description = "List of email addresses to subscribe to the SNS topic"
  type        = list(string)
  default     = []
}

variable "kms_key_arn" {
  description = "Optional KMS key ARN for SNS topic encryption"
  type        = string
  default     = null
}
