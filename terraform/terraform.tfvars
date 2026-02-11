cloudtrail_log_bucket_name = "my-unique-cloudtrail-logs-123456"
guardrails_target_name     = "my-iam-user-or-role"

cloudtrail_strict_trail_source_arn       = true
cloudtrail_allow_organization_log_writes = false
cloudtrail_is_organization_trail         = false

enable_cloudtrail_auto_remediation = true
remediation_log_retention_days     = 14

enable_org_scp = false

#or


cloudtrail_log_bucket_name = "org-central-cloudtrail-logs-123456"
guardrails_target_name     = "my-iam-user-or-role"

cloudtrail_is_organization_trail         = true
cloudtrail_allow_organization_log_writes = true

enable_org_scp       = true
org_scp_target_id    = "r-xxxx" # root / OU / account
org_scp_exempt_principal_arns = [
  "arn:aws:iam::123456789012:role/TerraformAdmin"
]
