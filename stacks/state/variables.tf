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
variable "bucket_name" {
  type = string
}
