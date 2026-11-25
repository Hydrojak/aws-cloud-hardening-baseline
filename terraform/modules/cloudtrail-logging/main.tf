terraform {
  required_providers {
    aws = { source = "hashicorp/aws", configuration_aliases = [aws.archive] }
  }
}
# CloudTrail logging baseline (cost-conscious)
# NOTE: Without AWS credentials, you can validate syntax but not plan/apply.

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  use_kms                    = var.use_kms != null ? var.use_kms : var.kms_key_arn != null
  owner_id                   = coalesce(var.trail_owner_id, data.aws_caller_identity.current.account_id)
  allow_multi_account_writes = var.allow_organization_log_writes || var.is_organization_trail
}
locals {
  s3_data_event_values = [for arn in var.s3_data_event_bucket_arns : (endswith(arn, "/") ? arn : "${arn}/")]

  enable_s3_data_events_effective     = var.enable_s3_data_events && length(var.s3_data_event_bucket_arns) > 0
  enable_lambda_data_events_effective = var.enable_lambda_data_events && length(var.lambda_data_event_function_arns) > 0
  enable_data_events                  = local.enable_s3_data_events_effective || local.enable_lambda_data_events_effective
}

resource "aws_s3_bucket" "trail_logs" {
  provider            = aws.archive
  bucket              = var.log_bucket_name
  force_destroy       = var.force_destroy_bucket
  object_lock_enabled = var.object_lock_days > 0 ? true : null
  lifecycle {
    precondition {
      condition     = !local.allow_multi_account_writes || can(regex("^o-[a-z0-9]{10,32}$", var.organization_id))
      error_message = "Organization delivery requires a real organization_id."
    }
    precondition {
      condition     = !(var.force_destroy_bucket && var.object_lock_days > 0)
      error_message = "An archive with retention cannot be force-destroyed."
    }
  }
}

# Recommended hardening: avoid ACL ownership edge cases
resource "aws_s3_bucket_ownership_controls" "trail_logs" {
  provider = aws.archive
  bucket   = aws_s3_bucket.trail_logs.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "trail_logs" {
  provider = aws.archive
  bucket   = aws_s3_bucket.trail_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "trail_logs" {
  provider = aws.archive
  bucket   = aws_s3_bucket.trail_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Encryption: SSE-S3 by default; optionally SSE-KMS if kms_key_arn is set
resource "aws_s3_bucket_server_side_encryption_configuration" "trail_logs_sse_s3" {
  provider = aws.archive
  count    = local.use_kms ? 0 : 1
  bucket   = aws_s3_bucket.trail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256" # SSE-S3 (free)
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "trail_logs_sse_kms" {
  provider = aws.archive
  count    = local.use_kms ? 1 : 0
  bucket   = aws_s3_bucket.trail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
  }
}

# Optional lifecycle to avoid infinite growth (set retention_days > 0)
resource "aws_s3_bucket_lifecycle_configuration" "trail_logs" {
  provider = aws.archive
  count    = var.retention_days > 0 ? 1 : 0
  bucket   = aws_s3_bucket.trail_logs.id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"
    filter {}
    noncurrent_version_expiration {
      noncurrent_days = var.retention_days
    }
    expiration {
      days = var.retention_days
    }
  }
}

# Deny non-TLS access to the log bucket + allow CloudTrail delivery
resource "aws_s3_bucket_policy" "trail_logs" {
  provider = aws.archive
  bucket   = aws_s3_bucket.trail_logs.id

  policy = module.archive_policy.json
}

moved {
  from = aws_cloudtrail.baseline
  to   = aws_cloudtrail.baseline[0]
}
resource "aws_cloudtrail" "baseline" {
  count                         = var.create_trail ? 1 : 0
  name                          = var.trail_name
  s3_bucket_name                = aws_s3_bucket.trail_logs.bucket
  include_global_service_events = true
  is_multi_region_trail         = var.is_multi_region_trail
  enable_log_file_validation    = true
  is_organization_trail         = var.is_organization_trail

  # Optional CloudTrail KMS encryption (in addition to S3 bucket default encryption)
  kms_key_id = var.kms_key_arn

  # Management events (déjà chez toi)
  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  # Data events (optionnel)
  dynamic "event_selector" {
    for_each = local.enable_data_events ? [1] : []
    content {
      read_write_type           = var.data_events_read_write_type
      include_management_events = false

      dynamic "data_resource" {
        for_each = local.enable_s3_data_events_effective ? [1] : []
        content {
          type   = "AWS::S3::Object"
          values = local.s3_data_event_values
        }
      }

      dynamic "data_resource" {
        for_each = local.enable_lambda_data_events_effective ? [1] : []
        content {
          type   = "AWS::Lambda::Function"
          values = var.lambda_data_event_function_arns
        }
      }
    }
  }

  lifecycle {
    precondition {
      condition     = (!var.enable_s3_data_events || length(var.s3_data_event_bucket_arns) > 0) && (!var.enable_lambda_data_events || length(var.lambda_data_event_function_arns) > 0)
      error_message = "Enabled data selectors require explicit resource ARNs."
    }
  }
  depends_on = [aws_s3_bucket_policy.trail_logs, aws_s3_bucket_versioning.trail_logs, aws_s3_bucket_server_side_encryption_configuration.trail_logs_sse_s3, aws_s3_bucket_server_side_encryption_configuration.trail_logs_sse_kms, aws_s3_bucket_object_lock_configuration.archive]
}

resource "aws_s3_bucket_object_lock_configuration" "archive" {
  provider = aws.archive
  count    = var.object_lock_days > 0 ? 1 : 0
  bucket   = aws_s3_bucket.trail_logs.id
  rule {
    default_retention {
      mode = "GOVERNANCE"
      days = var.object_lock_days
    }
  }
  depends_on = [aws_s3_bucket_versioning.trail_logs]
}

module "archive_policy" {
  source                  = "../archive-policy"
  bucket_arn              = aws_s3_bucket.trail_logs.arn
  owner_id                = local.owner_id
  partition               = data.aws_partition.current.partition
  trail_home_region       = var.trail_home_region
  trail_name              = var.trail_name
  strict_trail_source_arn = var.strict_trail_source_arn
  allow_multi_account     = local.allow_multi_account_writes
  organization_id         = var.organization_id
}
