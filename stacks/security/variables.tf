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
variable "source_accounts" {
  type = set(string)
  validation {
    condition     = length(var.source_accounts) > 0 && alltrue([for id in var.source_accounts : can(regex("^[0-9]{12}$", id))])
    error_message = "Supply an explicit list of sending accounts."
  }
}
variable "alert_email" {
  type = string
  validation {
    condition     = can(regex("^[^ @]+@[^ @]+\\.[^ @]+$", var.alert_email))
    error_message = "Set an email address and confirm the SNS subscription."
  }
}
variable "retention_days" {
  type    = number
  default = 90
}
