variable "recovery_user_arn" {
  type        = string
  default     = null
  description = "Optional independent IAM recovery identity whose hardware MFA and credentials are managed separately."
  validation {
    condition     = var.recovery_user_arn == null ? true : can(regex("^arn:aws:iam::[0-9]{12}:user/[a-zA-Z0-9+=,.@_/-]+$", var.recovery_user_arn))
    error_message = "Set an exact IAM recovery user ARN."
  }
}
resource "aws_iam_role" "recovery" {
  count                = var.recovery_user_arn == null ? 0 : 1
  name                 = "baseline-emergency-forwarding"
  max_session_duration = 3600
  assume_role_policy = jsonencode({
    Version = "2012-10-17", Statement = [{
      Effect    = "Allow", Principal = { AWS = var.recovery_user_arn }, Action = "sts:AssumeRole",
      Condition = { Bool = { "aws:MultiFactorAuthPresent" = "true" }, NumericLessThanEquals = { "aws:MultiFactorAuthAge" = 3600 } }
    }]
  })
}
resource "aws_iam_role_policy" "recovery" {
  count = var.recovery_user_arn == null ? 0 : 1
  role  = aws_iam_role.recovery[0].id
  policy = jsonencode({ Version = "2012-10-17", Statement = [{
    Effect   = "Allow",
    Action   = ["events:DescribeRule", "events:ListTargetsByRule", "events:EnableRule"],
    Resource = [for region in sort(var.regions) : "arn:aws:events:${region}:${var.account_id}:rule/baseline-forward-*"]
  }] })
}
