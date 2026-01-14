# V2.2 - Alerting layer
# CloudWatch Metric Filters + Alarms
# Triggered by detection events written to CloudWatch Logs

# --- CloudTrail tampering
resource "aws_cloudwatch_log_metric_filter" "cloudtrail_tampering" {
  name           = "detect-cloudtrail-tampering"
  log_group_name = var.log_group_name

  pattern = "{ ($.detail.eventSource = \"cloudtrail.amazonaws.com\") && ( $.detail.eventName = \"StopLogging\" || $.detail.eventName = \"DeleteTrail\" || $.detail.eventName = \"UpdateTrail\" || $.detail.eventName = \"PutEventSelectors\" || $.detail.eventName = \"PutInsightSelectors\" ) }"

  metric_transformation {
    name      = "CloudTrailTampering"
    namespace = var.namespace
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "cloudtrail_tampering" {
  alarm_name          = "ALERT-CloudTrail-Tampering"
  alarm_description   = "High-risk: CloudTrail was modified or stopped (possible tampering)."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  period              = var.period_seconds
  threshold           = var.threshold
  statistic           = "Sum"

  namespace   = var.namespace
  metric_name = aws_cloudwatch_log_metric_filter.cloudtrail_tampering.metric_transformation[0].name

  treat_missing_data = "notBreaching"
}

# --- IAM policy changes (privilege escalation signals)
resource "aws_cloudwatch_log_metric_filter" "iam_policy_changes" {
  name           = "detect-iam-policy-changes"
  log_group_name = var.log_group_name

  pattern = "{ ($.detail.eventSource = \"iam.amazonaws.com\") && ( $.detail.eventName = \"AttachUserPolicy\" || $.detail.eventName = \"AttachRolePolicy\" || $.detail.eventName = \"AttachGroupPolicy\" || $.detail.eventName = \"PutUserPolicy\" || $.detail.eventName = \"PutRolePolicy\" || $.detail.eventName = \"PutGroupPolicy\" || $.detail.eventName = \"CreatePolicy\" || $.detail.eventName = \"CreatePolicyVersion\" || $.detail.eventName = \"SetDefaultPolicyVersion\" ) }"

  metric_transformation {
    name      = "IamPolicyChanges"
    namespace = var.namespace
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "iam_policy_changes" {
  alarm_name          = "ALERT-IAM-Policy-Changes"
  alarm_description   = "High-risk: IAM policy changes detected (possible privilege escalation)."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  period              = var.period_seconds
  threshold           = var.threshold
  statistic           = "Sum"

  namespace   = var.namespace
  metric_name = aws_cloudwatch_log_metric_filter.iam_policy_changes.metric_transformation[0].name

  treat_missing_data = "notBreaching"
}

# --- Credential creation
resource "aws_cloudwatch_log_metric_filter" "credential_creation" {
  name           = "detect-credential-creation"
  log_group_name = var.log_group_name

  pattern = "{ ($.detail.eventSource = \"iam.amazonaws.com\") && ( $.detail.eventName = \"CreateAccessKey\" || $.detail.eventName = \"CreateLoginProfile\" || $.detail.eventName = \"UpdateLoginProfile\" ) }"

  metric_transformation {
    name      = "CredentialCreation"
    namespace = var.namespace
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "credential_creation" {
  alarm_name          = "ALERT-Credential-Creation"
  alarm_description   = "High-risk: new credentials were created or updated."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  period              = var.period_seconds
  threshold           = var.threshold
  statistic           = "Sum"

  namespace   = var.namespace
  metric_name = aws_cloudwatch_log_metric_filter.credential_creation.metric_transformation[0].name

  treat_missing_data = "notBreaching"
}

# --- S3 exposure attempts
resource "aws_cloudwatch_log_metric_filter" "s3_exposure" {
  name           = "detect-s3-exposure"
  log_group_name = var.log_group_name

  pattern = "{ ($.detail.eventSource = \"s3.amazonaws.com\") && ( $.detail.eventName = \"PutBucketAcl\" || $.detail.eventName = \"PutBucketPolicy\" || $.detail.eventName = \"DeleteBucketPolicy\" || $.detail.eventName = \"PutBucketPublicAccessBlock\" ) }"

  metric_transformation {
    name      = "S3ExposureAttempts"
    namespace = var.namespace
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "s3_exposure" {
  alarm_name          = "ALERT-S3-Exposure-Attempt"
  alarm_description   = "High-risk: S3 exposure-related changes detected."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  period              = var.period_seconds
  threshold           = var.threshold
  statistic           = "Sum"

  namespace   = var.namespace
  metric_name = aws_cloudwatch_log_metric_filter.s3_exposure.metric_transformation[0].name

  treat_missing_data = "notBreaching"
}
