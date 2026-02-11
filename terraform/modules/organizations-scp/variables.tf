variable "target_id" {
  description = "Organizations target to attach the SCP to (root/OU/account id, e.g. r-xxxx, ou-xxxx-xxxx, or 123456789012)."
  type        = string
}

variable "policy_name" {
  description = "Name of the SCP policy"
  type        = string
  default     = "baseline-cloud-hardening-scp"
}

variable "exempt_principal_arns" {
  description = "Optional list of principal ARNs that should NOT be affected by the SCP denies (e.g. break-glass / Terraform admin role)."
  type        = list(string)
  default     = []
}
