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
variable "regions" {
  type    = set(string)
  default = ["eu-west-1", "us-east-1"]
  validation {
    condition     = contains(var.regions, "us-east-1") && contains(var.regions, var.home_region)
    error_message = "Include the home region and us-east-1."
  }
}
variable "central_bus_arn" {
  type = string
  validation {
    condition     = can(regex("^arn:aws:events:[a-z0-9-]+:[0-9]{12}:event-bus/baseline-security$", var.central_bus_arn))
    error_message = "Supply the central baseline-security bus ARN."
  }
}
variable "manage_account_bpa" {
  type    = bool
  default = false
}
variable "manage_password_policy" {
  type    = bool
  default = false
}
variable "enable_external_analyzer" {
  type    = bool
  default = true
}
variable "manage_guardduty" {
  type    = bool
  default = false
}
variable "manage_cspm" {
  type    = bool
  default = false
}
variable "manage_hub_v2" {
  type    = bool
  default = false
}
variable "regional_alert_topics" {
  type    = map(string)
  default = {}
}
variable "alert_email" {
  type = string
  validation {
    condition     = can(regex("^[^ @]+@[^ @]+\\.[^ @]+$", var.alert_email))
    error_message = "Set a regional alert recipient."
  }
}
variable "guardduty_features" {
  type    = set(string)
  default = []
  validation {
    condition     = length(setsubtract(var.guardduty_features, toset(["RUNTIME_MONITORING", "AI_PROTECTION"]))) == 0
    error_message = "Select RUNTIME_MONITORING and/or AI_PROTECTION."
  }
}
