variable "log_group_name" {
  description = "CloudWatch Log Group name that receives detection events"
  type        = string
}

variable "namespace" {
  description = "CloudWatch custom metric namespace"
  type        = string
  default     = "CloudHardeningBaseline/Detections"
}

variable "period_seconds" {
  description = "Alarm period in seconds"
  type        = number
  default     = 300
}

variable "threshold" {
  description = "Alarm threshold (count of matched events per period)"
  type        = number
  default     = 1
}

variable "sns_topic_arn" {
  description = "Optional SNS topic ARN for alarm notifications (null disables actions)"
  type        = string
  default     = null
}
