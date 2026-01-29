# CloudTrail logging baseline (cost-conscious)
# NOTE: Without AWS credentials, you can validate syntax but not plan/apply.

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}
resource "aws_s3_bucket" "trail_logs" {
  bucket        = var.log_bucket_name
  force_destroy = var.force_destroy_bucket
}

# Recommended hardening: avoid ACL ownership edge cases
resource "aws_s3_bucket_ownership_controls" "trail_logs" {
  bucket = aws_s3_bucket.trail_logs.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "trail_logs" {
  bucket = aws_s3_bucket.trail_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "trail_logs" {
  bucket = aws_s3_bucket.trail_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Encryption: SSE-S3 by default; optionally SSE-KMS if kms_key_arn is set
resource "aws_s3_bucket_server_side_encryption_configuration" "trail_logs_sse_s3" {
  count  = var.kms_key_arn == null ? 1 : 0
  bucket = aws_s3_bucket.trail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256" # SSE-S3 (free)
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "trail_logs_sse_kms" {
  count  = var.kms_key_arn != null ? 1 : 0
  bucket = aws_s3_bucket.trail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
  }
}

# Optional lifecycle to avoid infinite growth (set retention_days > 0)
resource "aws_s3_bucket_lifecycle_configuration" "trail_logs" {
  count  = var.retention_days > 0 ? 1 : 0
  bucket = aws_s3_bucket.trail_logs.id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"
    filter {}
    expiration {
      days = var.retention_days
    }
  }
}

# Deny non-TLS access to the log bucket + allow CloudTrail delivery
resource "aws_s3_bucket_policy" "trail_logs" {
  bucket = aws_s3_bucket.trail_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.trail_logs.arn,
          "${aws_s3_bucket.trail_logs.arn}/*"
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      },
      {
        Sid       = "AWSCloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.trail_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"      = "bucket-owner-full-control"
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:${data.aws_partition.current.partition}:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/${var.trail_name}"
          }
        }
      },
      {
        Sid       = "AWSCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.trail_logs.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:${data.aws_partition.current.partition}:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/${var.trail_name}"
          }
        }
      }
    ]
  })
}


resource "aws_cloudtrail" "baseline" {
  name                          = var.trail_name
  s3_bucket_name                = aws_s3_bucket.trail_logs.bucket
  include_global_service_events = true
  is_multi_region_trail         = var.is_multi_region_trail
  enable_log_file_validation    = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  depends_on = [aws_s3_bucket_policy.trail_logs]
}
