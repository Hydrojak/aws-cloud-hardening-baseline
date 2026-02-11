# AWS Cloud Hardening Baseline (Terraform)
> Security baseline • Terraform • Blue Team • Lab-tested

A **cost-conscious AWS security baseline** focused on **hardening, detection, alerting, and optional remediation**, implemented entirely with **Terraform modules**.

This project is designed as a **Blue Team / Cloud Security portfolio baseline**: secure defaults, explicit guardrails, high-signal detections based on CloudTrail events — without relying on expensive managed security services.

---

## Project goals

- Reduce the AWS attack surface with preventive controls
- Ensure audit and forensic readiness
- Detect high-risk security events
- Provide actionable alerts
- Optionally auto-remediate critical logging tampering
- Remain free-tier friendly and easy to reason about

---

## What this baseline provides

### Hardening (preventive controls)

- **IAM baseline**
  - Strong account password policy
  - IAM Access Analyzer enabled at account level

- **Centralized audit logging**
  - CloudTrail enabled for management events
  - Multi-region trail (configurable)
  - Log file integrity validation enabled
  - Optional organization trail support
  - Dedicated hardened S3 bucket for logs:
    - Block Public Access enabled
    - Versioning enabled
    - TLS-only bucket policy
    - Encryption at rest (SSE-S3 by default, optional SSE-KMS)
    - Optional lifecycle expiration
    - Stricter CloudTrail bucket policy conditions:
      - Confused deputy protection using `aws:SourceAccount`
      - Trail-bound writes using `aws:SourceArn`
      - Optional multi-account delivery support for org trails (`AWSLogs/*`)

- **S3 guardrails**
  - Explicit deny policies preventing:
    - Making buckets public (ACLs, policies, public access block)
    - Disabling account-level S3 Public Access Block
  - Policies can be attached to a user or role

- **Optional organization-level guardrails**
  - Service Control Policy (SCP) module
  - Prevents:
    - CloudTrail tampering (StopLogging, DeleteTrail, UpdateTrail, PutEventSelectors, PutInsightSelectors)
    - Disabling S3 Public Access Block
    - Leaving the organization
  - Optional exemption list for break-glass / Terraform roles

---

### Detection (visibility)

- **EventBridge detection rules** based on CloudTrail logs:
  - CloudTrail tampering attempts
  - IAM policy changes
  - Credential creation events
  - S3 exposure attempts

- **Centralized detection log**
  - CloudWatch Logs log group dedicated to security detections
  - Retention configurable (default: 30 days)

---

### Alerting (signal escalation)

- CloudWatch metric filters on detection logs
- CloudWatch alarms for each detection category
- Optional SNS topic for alert delivery
- Optional email subscription for notifications
- Allow using an existing SNS topic instead of always creating one”
- Exemple tfvars avec `create_sns_topic=false` + `alarm_sns_topic_arn=...`
---

### Optional automated remediation

- Lambda-based auto-remediation module
- Triggered by EventBridge when CloudTrail tampering is detected
- Can:
  - Re-enable logging after `StopLogging`
  - Re-apply baseline settings after `UpdateTrail`
  - Restore expected event selectors
- Disabled by default
- Fully optional and modular

---

## Architecture

```mermaid
flowchart TB
  Dev["You"] --> TF["Terraform (root module)"]

  TF --> IAM["iam-baseline"]
  TF --> CTL["cloudtrail-logging"]
  TF --> GR["s3-guardrails"]

  TF --> CW["alerting-cloudwatch (log group + policy)"]
  TF --> EB["detection-eventbridge (rules -> logs)"]
  TF --> AL["alerting-alarms (metric filters + alarms)"]
  TF --> SNS["alerting-sns (optional)"]

  TF --> REM["remediation-cloudtrail (optional)"]
  TF --> SCP["organizations-scp (optional)"]

  IAM --> PP["Account password policy"]
  IAM --> AA["Access Analyzer"]

  CTL --> CT["CloudTrail (management events)"]
  CTL --> S3["S3 log bucket (hardened)"]
  CT --> S3

  EB --> CWL["CloudWatch Log Group: detections"]
  CW --> CWL

  CWL --> MF["Metric Filters"]
  MF --> A["CloudWatch Alarms"]
  A --> SNS

  EB --> REM
```

---

## Terraform modules

- **iam-baseline**
  - Account password policy
  - IAM Access Analyzer

- **cloudtrail-logging**
  - CloudTrail (management events)
  - Multi-region support
  - Optional organization trail
  - Hardened S3 log bucket
  - Strict bucket policy conditions
  - Optional lifecycle expiration
  - Optional KMS encryption

- **s3-guardrails**
  - Explicit deny IAM policy preventing S3 public exposure
  - Attachment to IAM user or role

- **alerting-cloudwatch**
  - CloudWatch Logs log group for detections
  - Resource policy allowing EventBridge to write logs

- **detection-eventbridge**
  - EventBridge rules for security-relevant CloudTrail events
  - Log group as target
  - Optional Lambda invocation for auto-remediation

- **alerting-alarms**
  - CloudWatch metric filters
  - CloudWatch alarms for:
    - CloudTrail tampering
    - IAM policy changes
    - Credential creation
    - S3 exposure attempts

- **alerting-sns**
  - SNS topic
  - Optional email subscription

- **remediation-cloudtrail (optional)**
  - Lambda function
  - IAM role and permissions
  - Automatically restores CloudTrail baseline configuration

- **organizations-scp (optional)**
  - Service Control Policy
  - Organization-level enforcement
  - Optional exemption list

---

## Cost considerations

This baseline is designed to remain **near $0** for a lab or portfolio environment:

- CloudTrail uses management events only
- CloudWatch Logs retention is limited
- S3 lifecycle expiration is optional
- Lambda is invoked only on security events

The following services are deliberately not used:

- GuardDuty
- Security Hub
- VPC Flow Logs
- OpenSearch / SIEM stacks
- NAT Gateways
- EC2 or persistent compute

**Important:** enabling KMS encryption may introduce additional costs.  
Organization-level features require AWS Organizations permissions.

---

## Usage

### Prerequisites

- Terraform `= 1.6`
- AWS credentials (only required for `plan/apply`)
- A globally-unique S3 bucket name for CloudTrail logs

---

## Quick start (static validation)

```bash
cd terraform
terraform init
terraform fmt -check
terraform validate
```

## Deploy in AWS (lab)

Create a `terraform.tfvars`:

```hcl
cloudtrail_log_bucket_name = "my-unique-cloudtrail-logs-123456"
guardrails_target_name     = "my-iam-user-or-role"

# Optional
cw_log_retention_days      = 30
cloudtrail_retention_days  = 0 # 0 disables expiration
sns_email                  = null # set to "you@domain.com" to receive alerts

# Advanced options
enable_cloudtrail_auto_remediation = false
cloudtrail_is_organization_trail   = false
enable_org_scp                     = false
```

Then:

```bash
terraform plan
terraform apply
```

## Destroy

```bash
terraform destroy
```

---

## Deployment notes

- Terraform state is ignored by default; for real usage, a remote encrypted backend is recommended.
- Guardrail policies use explicit deny and can block destructive actions.
  - In practice, Terraform should be executed using a dedicated role not restricted by the guardrails,
    or guardrails should be attached after the baseline is deployed.
- SCP deployment must be executed from the AWS Organizations management account.
- `enable_guardrails_attachment = false` -> “creates policy only”
---

## Detection testing (example scenarios)

You can generate detections with AWS CLI actions such as:

- `iam:CreateAccessKey`
- `iam:AttachUserPolicy`
- `cloudtrail:StopLogging`
- `cloudtrail:UpdateTrail`
- `s3:PutBucketPolicy`

Detections are written to:
- CloudWatch Logs: `/aws/cloud-hardening-baseline/detections` (default)

Alarms:

- `ALERT-CloudTrail-Tampering`
- `ALERT-IAM-Policy-Changes`
- `ALERT-Credential-Creation`
- `ALERT-S3-Exposure-Attempt`

---

## Documentation

- CIS mapping: `docs/cis-mapping.md`
- Hardening decisions: `docs/hardening-decisions.md`
- Detection logic: `docs/detection.md`
- References: `docs/references.md`
- Versioning policy: `docs/versioning.md`
- Changelog: `docs/changelog.md`

---

## Known limitations

- Event propagation from CloudTrail to EventBridge is not instantaneous
- This baseline does not aim to provide full security coverage
- SNS notifications are optional
- KMS usage may affect the cost model
- Auto-remediation is intentionally conservative and does not recreate deleted trails

---

## Roadmap ideas

- Allow using an existing SNS topic instead of always creating one
- Extend auto-remediation logic
- Add data event logging options (cost-aware toggle)
- Add GuardDuty integration module
- Add Security Hub integration module

---

## Author

Sacha Gatta-Boucard  
Cloud Security / Blue Team oriented portfolio project
