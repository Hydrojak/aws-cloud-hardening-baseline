variable "region" { type = string }
variable "account_id" { type = string }
variable "topic_name" { type = string }
resource "aws_kms_key" "alerts" {
  region                  = var.region
  description             = "SNS encryption for ${var.topic_name}"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AccountAdministration"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${var.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AlarmDelivery"
        Effect    = "Allow"
        Principal = { Service = "cloudwatch.amazonaws.com" }
        Action    = ["kms:Decrypt", "kms:GenerateDataKey*"]
        Resource  = "*"
        Condition = {
          StringEquals = { "aws:SourceAccount" = var.account_id }
          ArnLike      = { "aws:SourceArn" = "arn:aws:cloudwatch:${var.region}:${var.account_id}:alarm:*" }
        }
      }
    ]
  })
}
output "arn" { value = aws_kms_key.alerts.arn }
