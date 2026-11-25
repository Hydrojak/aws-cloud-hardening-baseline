variable "additional_detection_regions" {
  description = "Regions whose management events should reach the lab's home event bus."
  type        = set(string)
  default     = ["us-east-1"]
}
data "aws_partition" "lab" {}
data "aws_caller_identity" "lab" {}
locals {
  extra_regions = setsubtract(var.additional_detection_regions, toset([var.aws_region]))
  home_bus      = "arn:${data.aws_partition.lab.partition}:events:${var.aws_region}:${data.aws_caller_identity.lab.account_id}:event-bus/default"
}
resource "aws_cloudwatch_event_rule" "lab_relay" {
  for_each = local.extra_regions
  region   = each.key
  name     = "baseline-lab-forward"
  event_pattern = jsonencode({
    account       = [data.aws_caller_identity.lab.account_id]
    source        = ["aws.iam", "aws.s3", "aws.cloudtrail", "aws.guardduty", "aws.securityhub"]
    "detail-type" = ["AWS API Call via CloudTrail", "GuardDuty Finding", "Security Hub Findings - Imported"]
    "$or" = [
      { detail = { eventName = ["StopLogging", "DeleteTrail", "UpdateTrail", "PutEventSelectors", "PutInsightSelectors", "AttachUserPolicy", "AttachRolePolicy", "AttachGroupPolicy", "PutUserPolicy", "PutRolePolicy", "PutGroupPolicy", "CreatePolicy", "CreatePolicyVersion", "SetDefaultPolicyVersion", "CreateAccessKey", "CreateLoginProfile", "UpdateLoginProfile", "PutBucketAcl", "PutBucketPolicy", "DeleteBucketPolicy", "PutBucketPublicAccessBlock", "DeleteBucketPublicAccessBlock", "PutAccountPublicAccessBlock", "DeleteAccountPublicAccessBlock", "PutPublicAccessBlock", "DeletePublicAccessBlock"] } },
      { "detail-type" = ["GuardDuty Finding", "Security Hub Findings - Imported"] }
    ]
  })
}
resource "aws_iam_role" "lab_relay" {
  for_each = local.extra_regions
  name     = "baseline-lab-forward-${each.key}"
  assume_role_policy = jsonencode({ Version = "2012-10-17", Statement = [{
    Effect    = "Allow", Principal = { Service = "events.amazonaws.com" }, Action = "sts:AssumeRole",
    Condition = { ArnEquals = { "aws:SourceArn" = aws_cloudwatch_event_rule.lab_relay[each.key].arn }, StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.lab.account_id } }
  }] })
}
resource "aws_iam_role_policy" "lab_relay" {
  for_each = aws_iam_role.lab_relay
  role     = each.value.id
  policy   = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Action = "events:PutEvents", Resource = local.home_bus }] })
}
resource "aws_cloudwatch_event_target" "lab_relay" {
  for_each   = aws_cloudwatch_event_rule.lab_relay
  region     = each.key
  rule       = each.value.name
  target_id  = "home"
  arn        = local.home_bus
  role_arn   = aws_iam_role.lab_relay[each.key].arn
  depends_on = [aws_iam_role_policy.lab_relay]
}
check "notification_destination" {
  assert {
    condition     = var.create_sns_topic ? var.sns_email != null : var.alarm_sns_topic_arn != null
    error_message = "The lab has no configured alert recipient. Confirm an SNS email or provide a monitored topic."
  }
}
