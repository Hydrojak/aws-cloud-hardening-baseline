variable "home_region" {
  type    = string
  default = "eu-west-1"
}
variable "account_id" {
  type = string
  validation {
    condition     = can(regex("^[0-9]{12}$", var.account_id))
    error_message = "Use a twelve-digit AWS account ID."
  }
}
variable "management_account_id" {
  type = string
  validation {
    condition     = can(regex("^[0-9]{12}$", var.management_account_id))
    error_message = "Use a twelve-digit AWS account ID."
  }
}
variable "organization_id" {
  type = string
  validation {
    condition     = can(regex("^o-[a-z0-9]{10,32}$", var.organization_id))
    error_message = "Use an AWS organization ID."
  }
}
variable "bucket_name" {
  type = string
}
variable "trail_name" {
  type    = string
  default = "baseline-organization"
}
variable "retention_days" {
  type    = number
  default = 365
}
variable "object_lock_days" {
  type    = number
  default = 30
}
variable "kms_key_arn" {
  type    = string
  default = null
}
