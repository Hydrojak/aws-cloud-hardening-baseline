variables {
  bus_arn         = "arn:aws:events:eu-west-1:333333333333:event-bus/baseline-security"
  organization_id = "o-example12345"
  source_accounts = ["444444444444"]
}
run "only_forwarding_from_named_member_role_in_org" {
  command = plan
  assert {
    condition     = length(jsondecode(output.policy).Statement) == 1 && jsondecode(output.policy).Statement[0].Action == "events:PutEvents" && jsondecode(output.policy).Statement[0].Resource == var.bus_arn && toset(jsondecode(output.policy).Statement[0].Principal.AWS) == toset(["arn:aws:iam::444444444444:root"]) && jsondecode(output.policy).Statement[0].Condition.StringEquals["aws:PrincipalOrgID"] == var.organization_id && jsondecode(output.policy).Statement[0].Condition.Bool["events:eventBusInvocation"] == "true" && toset(jsondecode(output.policy).Statement[0].Condition.ArnLike["aws:PrincipalArn"]) == toset(["arn:aws:iam::444444444444:role/baseline-event-forward-*"])
    error_message = "Ingress boundary widened."
  }
}
run "reject_wildcard_sender" {
  command = plan
  variables { source_accounts = ["*"] }
  expect_failures = [var.source_accounts]
}
run "reject_wildcard_organization" {
  command = plan
  variables { organization_id = "*" }
  expect_failures = [var.organization_id]
}
