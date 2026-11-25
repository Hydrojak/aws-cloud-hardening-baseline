variable "bucket_arn" { type = string }
variable "owner_id" { type = string }
variable "partition" { type = string }
variable "trail_home_region" { type = string }
variable "trail_name" { type = string }
variable "strict_trail_source_arn" { type = bool }
variable "allow_multi_account" { type = bool }
variable "organization_id" { type = string }

locals {
  # Trail ARN used in S3 bucket policy conditions (to mitigate confused deputy issues)
  strict_trail_arn   = "arn:${var.partition}:cloudtrail:${var.trail_home_region}:${var.owner_id}:trail/${var.trail_name}"
  wildcard_trail_arn = "arn:${var.partition}:cloudtrail:*:${var.owner_id}:trail/${var.trail_name}"

  # For organization / centralized logging buckets, CloudTrail writes logs for multiple accounts under AWSLogs/<account-id>/...
  allow_multi_account_writes = var.allow_multi_account
  account_log_path           = "${var.bucket_arn}/AWSLogs/${var.owner_id}/*"
  cloudtrail_logs_resource   = local.allow_multi_account_writes ? [local.account_log_path, "${var.bucket_arn}/AWSLogs/${coalesce(var.organization_id, "invalid")}/*"] : [local.account_log_path]
}
output "json" {
  value = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          var.bucket_arn,
          "${var.bucket_arn}/*"
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
        Resource  = local.cloudtrail_logs_resource
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"      = "bucket-owner-full-control"
            "aws:SourceAccount" = var.owner_id
          }
          # If strict_trail_source_arn is enabled, restrict to the exact trail ARN in trail_home_region.
          # Otherwise, allow any region in the ARN (less strict, but more flexible).
          (var.strict_trail_source_arn ? "ArnEquals" : "ArnLike") = {
            "aws:SourceArn" = var.strict_trail_source_arn ? local.strict_trail_arn : local.wildcard_trail_arn
          }
        }
      },
      {
        Sid       = "AWSCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = var.bucket_arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = var.owner_id
          }
          (var.strict_trail_source_arn ? "ArnEquals" : "ArnLike") = {
            "aws:SourceArn" = var.strict_trail_source_arn ? local.strict_trail_arn : local.wildcard_trail_arn
          }
        }
      }
    ]
  })
  precondition {
    condition     = !var.allow_multi_account || can(regex("^o-[a-z0-9]{10,32}$", var.organization_id))
    error_message = "An organization log path needs an explicit organization."
  }
}
