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

variable "is_multi_region_trail" {
  description = "Whether CloudTrail is multi-region (recommended true for hardening)"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "Optional KMS key ARN for S3 log encryption (null = SSE-S3)"
  type        = string
  default     = null
}

variable "retention_days" {
  description = "Optional expiration days for S3 logs (0 disables expiration)"
  type        = number
  default     = 0
}
variable "trail_home_region" {
  description = "Home region for the trail ARN used in bucket policy conditions. Typically the same region as the Terraform AWS provider."
  type        = string
}

variable "strict_trail_source_arn" {
  description = "If true, bucket policy uses ArnEquals on the exact trail ARN (includes trail_home_region). If false, allows any region in the trail ARN."
  type        = bool
  default     = true
}

variable "allow_organization_log_writes" {
  description = "If true, allow CloudTrail delivery under AWSLogs/* (required for organization trails / centralized multi-account log buckets)."
  type        = bool
  default     = false
}

variable "is_organization_trail" {
  description = "If true, create an organization trail (must be applied from the AWS Organizations management account)."
  type        = bool
  default     = false
}

