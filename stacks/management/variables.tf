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
variable "organization_id" {
  type = string
  validation {
    condition     = can(regex("^o-[a-z0-9]{10,32}$", var.organization_id))
    error_message = "Use an AWS organization ID."
  }
}
variable "archive_account_id" {
  type = string
  validation {
    condition     = can(regex("^[0-9]{12}$", var.archive_account_id))
    error_message = "Use a twelve-digit AWS account ID."
  }
}
variable "bucket_name" {
  type = string
}
variable "trail_name" {
  type    = string
  default = "baseline-organization"
}
variable "kms_key_arn" {
  type = string
  validation {
    condition     = can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/", var.kms_key_arn))
    error_message = "Use the archive_key_arn output from the archive stack."
  }
}
variable "alert_email" {
  type = string
  validation {
    condition     = can(regex("^[^ @]+@[^ @]+\\.[^ @]+$", var.alert_email))
    error_message = "Set an email address and confirm the SNS subscription."
  }
}
variable "pilot_ou" {
  type = string
  validation {
    condition     = can(regex("^ou-[a-z0-9]{4,32}-[a-z0-9]{8,32}$", var.pilot_ou))
    error_message = "Choose a pilot OU."
  }
}
variable "apply_scp" {
  type    = bool
  default = false
}
variable "apply_s3_policy" {
  type    = bool
  default = false
}
variable "exception_role_arns" {
  type    = list(string)
  default = []
  validation {
    condition     = alltrue([for arn in var.exception_role_arns : can(regex("^arn:aws:iam::[0-9]{12}:role/[a-zA-Z0-9+=,.@_/-]+$", arn))])
    error_message = "Only explicit IAM role ARNs are allowed."
  }
}
variable "repair" {
  type    = bool
  default = false
}
variable "monthly_budget_usd" {
  type    = number
  default = null
  validation {
    condition     = var.monthly_budget_usd == null ? true : var.monthly_budget_usd > 0
    error_message = "Choose a positive USD budget or null."
  }
}
