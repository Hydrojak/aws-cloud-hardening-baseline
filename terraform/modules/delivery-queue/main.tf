variable "name" { type = string }
variable "region" { type = string }
variable "rule_arns" { type = list(string) }
variable "alert_topic" { type = string }
resource "aws_sqs_queue" "failed" {
  region                    = var.region
  name                      = "${var.name}-dlq"
  message_retention_seconds = 1209600
  sqs_managed_sse_enabled   = true
}
resource "aws_sqs_queue_policy" "ingress" {
  region    = var.region
  queue_url = aws_sqs_queue.failed.id
  policy = jsonencode({ Version = "2012-10-17", Statement = [
    { Sid = "RulesOnly", Effect = "Allow", Principal = { Service = "events.amazonaws.com" }, Action = "sqs:SendMessage", Resource = aws_sqs_queue.failed.arn, Condition = { ArnEquals = { "aws:SourceArn" = var.rule_arns } } },
    { Sid = "TLSOnly", Effect = "Deny", Principal = "*", Action = "sqs:*", Resource = aws_sqs_queue.failed.arn, Condition = { Bool = { "aws:SecureTransport" = "false" } } }
  ] })
}
resource "aws_cloudwatch_metric_alarm" "backlog" {
  region              = var.region
  alarm_name          = "${var.name}-delivery-failed"
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  dimensions          = { QueueName = aws_sqs_queue.failed.name }
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.alert_topic]
}
output "arn" {
  value      = aws_sqs_queue.failed.arn
  depends_on = [aws_sqs_queue_policy.ingress]
}
