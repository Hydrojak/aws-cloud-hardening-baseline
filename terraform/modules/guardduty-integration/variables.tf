variable "prefix" { type = string default = "baseline" }
variable "manage_detector" { type = bool default = true }
variable "severity_min" { type = number default = 7 }

variable "log_group_arn" { type = string }
variable "log_group_name" { type = string }

variable "sns_topic_arn" { type = string default = null }

variable "namespace" { type = string default = "CloudHardeningBaseline" }
variable "period_seconds" { type = number default = 60 }
variable "threshold" { type = number default = 1 }
