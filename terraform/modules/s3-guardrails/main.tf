# S3 Guardrails (cost: $0)
# Goal: prevent accidental public exposure of S3 buckets

data "aws_iam_policy_document" "s3_guardrails" {
  statement {
    sid    = "DenyMakingBucketsPublic"
    effect = "Deny"
    actions = [
      "s3:PutBucketAcl",
      "s3:PutObjectAcl",
      "s3:PutBucketPolicy",
      "s3:DeleteBucketPolicy",
      "s3:PutBucketPublicAccessBlock"
    ]
    resources = [
      "arn:aws:s3:::*",
      "arn:aws:s3:::*/*"
    ]
  }

  statement {
    sid    = "DenyDisablingAccountPublicAccessBlock"
    effect = "Deny"
    actions = [
      "s3:PutAccountPublicAccessBlock"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "s3_guardrails" {
  name        = "s3-guardrails-deny-public"
  description = "Guardrails to prevent making S3 public / disabling public access blocks"
  policy      = data.aws_iam_policy_document.s3_guardrails.json
}

resource "aws_iam_user_policy_attachment" "attach_to_user" {
  count      = var.target_type == "user" ? 1 : 0
  user       = var.target_iam_principal_name
  policy_arn = aws_iam_policy.s3_guardrails.arn
}

resource "aws_iam_role_policy_attachment" "attach_to_role" {
  count      = var.target_type == "role" ? 1 : 0
  role       = var.target_iam_principal_name
  policy_arn = aws_iam_policy.s3_guardrails.arn
}
