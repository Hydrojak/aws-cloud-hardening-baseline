variable "target_iam_principal_name" {
  description = "Name of the IAM user or role to attach the guardrail policy to"
  type        = string
}

variable "target_type" {
  description = "Either 'user' or 'role'"
  type        = string
  validation {
    condition     = contains(["user", "role"], var.target_type)
    error_message = "target_type must be 'user' or 'role'."
  }
}
variable "enable_attachment" {
  description = "Whether to attach the guardrails policy to the target principal."
  type        = bool
  default     = true
}

