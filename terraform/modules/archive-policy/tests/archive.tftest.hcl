variables {
  bucket_arn              = "arn:aws:s3:::archive-pilot"
  owner_id                = "111111111111"
  partition               = "aws"
  trail_home_region       = "eu-west-1"
  trail_name              = "org-trail"
  strict_trail_source_arn = true
  allow_multi_account     = true
  organization_id         = "o-example12345"
}
run "trail_bound_organization_delivery" {
  command = plan
  assert {
    condition     = jsondecode(output.json).Statement[1].Principal.Service == "cloudtrail.amazonaws.com" && jsondecode(output.json).Statement[1].Condition.ArnEquals["aws:SourceArn"] == "arn:aws:cloudtrail:eu-west-1:111111111111:trail/org-trail" && jsondecode(output.json).Statement[1].Condition.StringEquals["aws:SourceAccount"] == var.owner_id && toset(jsondecode(output.json).Statement[1].Resource) == toset(["arn:aws:s3:::archive-pilot/AWSLogs/o-example12345/*", "arn:aws:s3:::archive-pilot/AWSLogs/111111111111/*"])
    error_message = "Unscoped delivery access."
  }
}
run "tls_on_bucket_and_objects" {
  command = plan
  assert {
    condition     = jsondecode(output.json).Statement[0].Effect == "Deny" && jsondecode(output.json).Statement[0].Principal == "*" && jsondecode(output.json).Statement[0].Condition.Bool["aws:SecureTransport"] == "false" && toset(jsondecode(output.json).Statement[0].Resource) == toset([var.bucket_arn, "${var.bucket_arn}/*"])
    error_message = "TLS is not enforced for bucket and objects."
  }
}
run "standalone_has_only_account_prefix" {
  command = plan
  variables {
    allow_multi_account = false
    organization_id     = null
  }
  assert {
    condition     = toset(jsondecode(output.json).Statement[1].Resource) == toset(["arn:aws:s3:::archive-pilot/AWSLogs/111111111111/*"])
    error_message = "The single-account policy grants excess object prefixes."
  }
}
run "organization_id_required" {
  command = plan
  variables { organization_id = null }
  expect_failures = [output.json]
}
