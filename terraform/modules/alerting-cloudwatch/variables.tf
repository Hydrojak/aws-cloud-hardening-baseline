variable "log_group_name" {
  description = "CloudWatch Log Group name for detection events"
  type        = string
  default     = "/aws/cloud-hardening-baseline/detections"
}

variable "retention_days" {
  description = "Log retention in days (cost control)"
  type        = number
  default     = 7
}

variable "kms_key_arn" {
  description = "Optional KMS key ARN for log group encryption (null = no CMK)"
  type        = string
  default     = null
}
