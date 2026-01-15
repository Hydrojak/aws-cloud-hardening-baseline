# V2.1 - Detection sink: CloudWatch Log Group (cost-conscious)

resource "aws_cloudwatch_log_group" "detections" {
  name              = var.log_group_name
  retention_in_days = var.retention_days
}


resource "aws_cloudwatch_log_resource_policy" "allow_eventbridge_putlogs" {
  policy_name = "allow-eventbridge-to-put-logs"

  policy_document = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowEventBridgeToWrite",
        Effect    = "Allow",
        Principal = { Service = "events.amazonaws.com" },
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "${aws_cloudwatch_log_group.detections.arn}:*"
      }
    ]
  })
}
