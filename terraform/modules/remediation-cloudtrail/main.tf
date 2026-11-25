# Optional automated remediation (Lambda)
# Triggered by EventBridge when CloudTrail tampering is detected.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 6.74.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "= 2.8.1"
    }
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/index.py"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_iam_role" "lambda" {
  name = "${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "cloudtrail_remediate" {
  name = "${var.function_name}-cloudtrail-remediate"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "CloudTrailRemediation"
        Effect   = "Allow"
        Action   = concat(["cloudtrail:GetTrail", "cloudtrail:GetEventSelectors", "cloudtrail:GetTrailStatus"], var.repair ? ["cloudtrail:StartLogging", "cloudtrail:UpdateTrail", "cloudtrail:PutEventSelectors"] : [])
        Resource = local.trail_arn
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "${aws_cloudwatch_log_group.lambda.arn}:*"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days
}

resource "aws_lambda_function" "this" {
  function_name = var.function_name
  role          = aws_iam_role.lambda.arn
  runtime       = "python3.13"
  handler       = "index.handler"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  timeout                        = 30
  memory_size                    = 128
  reserved_concurrent_executions = var.concurrency_limit

  environment {
    variables = {
      TRAIL_ARN          = local.trail_arn
      EXPECTED_SELECTORS = jsonencode(local.selectors)
      EXPECTED_FLAGS     = jsonencode(merge({ S3BucketName = var.log_bucket_name, IncludeGlobalServiceEvents = true, IsMultiRegionTrail = var.is_multi_region_trail, EnableLogFileValidation = true }, var.kms_key_arn == null ? {} : { KmsKeyId = var.kms_key_arn }))
      HOME_REGION        = var.home_region
      ROLE_ARN           = aws_iam_role.lambda.arn
      REPAIR             = tostring(var.repair)
      ORG_TRAIL          = tostring(var.org_trail)
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda, aws_iam_role_policy.cloudtrail_remediate]
}
