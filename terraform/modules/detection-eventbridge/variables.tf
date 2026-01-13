variable "log_group_arn" {
  description = "CloudWatch Log Group ARN where detection events are sent"
  type        = string
}

variable "prefix" {
  description = "Prefix for detection rule names"
  type        = string
  default     = "baseline-detect"
}
