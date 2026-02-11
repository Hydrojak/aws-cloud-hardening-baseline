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

  deny_statement = merge(
    {
      Sid      = "DenyHighRiskSecurityDisables"
      Effect   = "Deny"
      Action   = local.deny_actions
      Resource = "*"
    },
      length(var.exempt_principal_arns) > 0 ? {
      Condition = {
        ArnNotLike = {
          "aws:PrincipalArn" = var.exempt_principal_arns
        }
      }
    } : {}
  )

  scp_content = {
    Version   = "2012-10-17"
    Statement = [local.deny_statement]
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
