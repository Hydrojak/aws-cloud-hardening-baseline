
variable "manage_securityhub" { type = bool default = true }

variable "severity_labels" { type = list(string) default = ["HIGH", "CRITICAL"] }
variable "record_states"   { type = list(string) default = ["ACTIVE"] }
variable "workflow_states" { type = list(string) default = [] }

variable "log_group_arn"  { type = string }
variable "log_group_name" { type = string }

variable "sns_topic_arn" { type = string default = null }

variable "namespace" { type = string default = "CloudHardeningBaseline" }
variable "period_seconds" { type = number default = 60 }
variable "threshold" { type = number default = 1 }
variable "prefix" {
  description = "Prefix used for resource names"
  type        = string
  default     = "baseline"
}
