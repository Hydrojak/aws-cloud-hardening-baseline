# V2.1 - Detection: EventBridge rules (CloudTrail) -> CloudWatch Logs

resource "aws_iam_role" "eventbridge_to_cwlogs" {
  name = "${var.prefix}-eventbridge-to-cwlogs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "events.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "eventbridge_to_cwlogs" {
  name = "${var.prefix}-cwlogs-policy"
  role = aws_iam_role.eventbridge_to_cwlogs.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      Resource = "${var.log_group_arn}:*"
    }]
  })
}
resource "aws_cloudwatch_event_rule" "cloudtrail_tampering" {
  name        = "${var.prefix}-cloudtrail-tampering"
  description = "Detect attempts to stop/delete/update CloudTrail"
  event_pattern = jsonencode({
    "detail-type" : ["AWS API Call via CloudTrail"],
    "detail" : {
      "eventSource" : ["cloudtrail.amazonaws.com"],
      "eventName" : [
        "StopLogging",
        "DeleteTrail",
        "UpdateTrail",
        "PutEventSelectors",
        "PutInsightSelectors"
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "cloudtrail_tampering_to_logs" {
  rule      = aws_cloudwatch_event_rule.cloudtrail_tampering.name
  target_id = "cwlogs"
  arn       = var.log_group_arn
  role_arn  = aws_iam_role.eventbridge_to_cwlogs.arn
}
resource "aws_cloudwatch_event_rule" "iam_policy_changes" {
  name        = "${var.prefix}-iam-policy-changes"
  description = "Detect IAM policy changes (potential privilege escalation)"
  event_pattern = jsonencode({
    "detail-type" : ["AWS API Call via CloudTrail"],
    "detail" : {
      "eventSource" : ["iam.amazonaws.com"],
      "eventName" : [
        "AttachUserPolicy",
        "AttachRolePolicy",
        "AttachGroupPolicy",
        "PutUserPolicy",
        "PutRolePolicy",
        "PutGroupPolicy",
        "CreatePolicy",
        "CreatePolicyVersion",
        "SetDefaultPolicyVersion"
      ]
    }
  })
}
resource "aws_cloudwatch_event_target" "iam_policy_changes_to_logs" {
  rule      = aws_cloudwatch_event_rule.iam_policy_changes.name
  target_id = "cwlogs"
  arn       = var.log_group_arn
  role_arn  = aws_iam_role.eventbridge_to_cwlogs.arn
}

resource "aws_cloudwatch_event_rule" "credential_creation" {
  name        = "${var.prefix}-credential-creation"
  description = "Detect creation of new credentials (keys/login profile)"
  event_pattern = jsonencode({
    "detail-type" : ["AWS API Call via CloudTrail"],
    "detail" : {
      "eventSource" : ["iam.amazonaws.com"],
      "eventName" : [
        "CreateAccessKey",
        "CreateLoginProfile",
        "UpdateLoginProfile"
      ]
    }
  })
}
resource "aws_cloudwatch_event_target" "credential_creation_to_logs" {
  rule      = aws_cloudwatch_event_rule.credential_creation.name
  target_id = "cwlogs"
  arn       = var.log_group_arn
  role_arn  = aws_iam_role.eventbridge_to_cwlogs.arn
}

resource "aws_cloudwatch_event_rule" "s3_exposure_changes" {
  name        = "${var.prefix}-s3-exposure-changes"
  description = "Detect S3 changes that may lead to public exposure"
  event_pattern = jsonencode({
    "detail-type" : ["AWS API Call via CloudTrail"],
    "detail" : {
      "eventSource" : ["s3.amazonaws.com"],
      "eventName" : [
        "PutBucketAcl",
        "PutBucketPolicy",
        "DeleteBucketPolicy",
        "PutBucketPublicAccessBlock"
      ]
    }
  })
}
resource "aws_cloudwatch_event_target" "s3_exposure_changes_to_logs" {
  rule      = aws_cloudwatch_event_rule.s3_exposure_changes.name
  target_id = "cwlogs"
  arn       = var.log_group_arn
  role_arn  = aws_iam_role.eventbridge_to_cwlogs.arn
}
