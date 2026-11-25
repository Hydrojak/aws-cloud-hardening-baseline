# The AWS service receives encryption privileges, not general read access to the archive.
resource "aws_kms_key" "archive" {
  count                   = var.kms_key_arn == null ? 1 : 0
  description             = "Organization CloudTrail archive"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  lifecycle { prevent_destroy = true }
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "ArchiveAdministration", Effect = "Allow",
        Principal = { AWS = "arn:aws:iam::${var.account_id}:root" },
        Action    = "kms:*", Resource = "*"
      },
      {
        Sid       = "TrailDelivery", Effect = "Allow", Principal = { Service = "cloudtrail.amazonaws.com" },
        Action    = "kms:GenerateDataKey*", Resource = "*",
        Condition = { StringEquals = { "aws:SourceArn" = local.trail_arn }, StringLike = { "kms:EncryptionContext:aws:cloudtrail:arn" = "arn:aws:cloudtrail:*:*:trail/${var.trail_name}" } }
      },
      {
        Sid    = "DescribeDeliveryKey", Effect = "Allow", Principal = { Service = "cloudtrail.amazonaws.com" },
        Action = "kms:DescribeKey", Resource = "*"
      },
      {
        Sid    = "TrailOwnerCanDescribe", Effect = "Allow", Principal = { AWS = "arn:aws:iam::${var.management_account_id}:root" },
        Action = "kms:DescribeKey", Resource = "*"
      }
    ]
  })
}
locals {
  trail_arn       = "arn:aws:cloudtrail:${var.home_region}:${var.management_account_id}:trail/${var.trail_name}"
  archive_key_arn = var.kms_key_arn == null ? aws_kms_key.archive[0].arn : var.kms_key_arn
}
output "archive_key_arn" { value = local.archive_key_arn }
