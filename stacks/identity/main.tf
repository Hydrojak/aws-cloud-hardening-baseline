# Run in the IAM Identity Center home region using the authorized administrator.
resource "aws_ssoadmin_permission_set" "investigator" {
  instance_arn     = var.instance_arn
  name             = "BaselineSecurityReview"
  session_duration = "PT2H"
  description      = "Read access to the central evidence log and baseline alarm status."
}
resource "aws_ssoadmin_permission_set_inline_policy" "review" {
  instance_arn       = var.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.investigator.arn
  inline_policy = jsonencode({ Version = "2012-10-17", Statement = [
    { Effect = "Allow", Action = ["logs:FilterLogEvents", "logs:GetLogEvents", "logs:DescribeLogStreams"], Resource = "arn:aws:logs:*:${var.security_account_id}:log-group:/aws/events/baseline-security:*" },
    { Effect = "Allow", Action = ["cloudwatch:DescribeAlarms", "cloudwatch:DescribeAlarmHistory"], Resource = "*" }
  ] })
}
resource "aws_ssoadmin_account_assignment" "investigators" {
  instance_arn       = var.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.investigator.arn
  principal_type     = "GROUP"
  principal_id       = var.security_group_id
  target_type        = "AWS_ACCOUNT"
  target_id          = var.security_account_id
  depends_on         = [aws_ssoadmin_permission_set_inline_policy.review]
}
