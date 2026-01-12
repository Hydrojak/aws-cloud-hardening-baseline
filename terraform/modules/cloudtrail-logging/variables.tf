variable "trail_name" {
  description = "Name of the CloudTrail trail"
  type        = string
  default     = "baseline-cloudtrail"
}

variable "log_bucket_name" {
  description = "S3 bucket name for CloudTrail logs (must be globally unique)"
  type        = string
}

variable "force_destroy_bucket" {
  description = "If true, allow destroying bucket even if it contains objects (useful for labs)"
  type        = bool
  default     = true
}
