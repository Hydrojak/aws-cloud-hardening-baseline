# Organization-level deployment: Service Control Policy (SCP)
#
# IMPORTANT:
# - Must be applied from the AWS Organizations MANAGEMENT account.
# - SCP limits maximum permissions. Exempt your Terraform/admin role if needed.

locals {
  deny_actions = [
    # Prevent CloudTrail tampering (audit/forensic readiness)
    "cloudtrail:StopLogging",
    "cloudtrail:DeleteTrail",
    "cloudtrail:UpdateTrail",
    "cloudtrail:PutEventSelectors",
    "cloudtrail:PutInsightSelectors",

    # Prevent S3 public access guardrails from being disabled
    "s3:PutAccountPublicAccessBlock",
    "s3:PutBucketPublicAccessBlock",

    # Reduce blast-radius from org escape
    "organizations:LeaveOrganization"
  ]

  exception = length(var.exempt_principal_arns) == 0 ? {} : {
    Condition = { ArnNotEquals = { "aws:PrincipalArn" = var.exempt_principal_arns } }
  }
  protected_controls = [
    {
      Sid      = "ProtectBaselineRules"
      Action   = ["events:DisableRule", "events:DeleteRule", "events:RemoveTargets", "events:PutRule", "events:PutTargets"]
      Resource = ["arn:aws:events:*:*:rule/baseline-forward-*", "arn:aws:events:*:*:rule/baseline-security/baseline-receive-*"]
    },
    {
      Sid      = "ProtectEvidenceLog"
      Action   = ["logs:DeleteLogGroup", "logs:DeleteLogStream", "logs:PutRetentionPolicy", "logs:DeleteRetentionPolicy"]
      Resource = ["arn:aws:logs:*:*:log-group:/aws/events/baseline-security", "arn:aws:logs:*:*:log-group:/aws/events/baseline-security:*"]
    },
    {
      Sid      = "ProtectForwardingRoles"
      Action   = ["iam:UpdateAssumeRolePolicy", "iam:PutRolePolicy", "iam:DeleteRolePolicy", "iam:DeleteRole", "iam:AttachRolePolicy"]
      Resource = ["arn:aws:iam::*:role/baseline-event-forward-*"]
    }
  ]
  scp_content = {
    Version = "2012-10-17"
    Statement = concat(
      [merge({ Sid = "DenyHighRiskSecurityDisables", Effect = "Deny", Action = local.deny_actions, Resource = "*" }, local.exception)],
      [for entry in local.protected_controls : merge(entry, { Effect = "Deny" }, local.exception)],
      var.archive_bucket_arn == null ? [] : [merge({
        Sid      = "ProtectArchiveVersions", Effect = "Deny",
        Action   = ["s3:DeleteObjectVersion", "s3:BypassGovernanceRetention", "s3:PutObjectRetention"],
        Resource = "${var.archive_bucket_arn == null ? "" : var.archive_bucket_arn}/*"
      }, local.exception)]
    )
  }
}

resource "aws_organizations_policy" "this" {
  name    = var.policy_name
  type    = "SERVICE_CONTROL_POLICY"
  content = jsonencode(local.scp_content)
}

resource "aws_organizations_policy_attachment" "this" {
  policy_id = aws_organizations_policy.this.id
  target_id = var.target_id
}
