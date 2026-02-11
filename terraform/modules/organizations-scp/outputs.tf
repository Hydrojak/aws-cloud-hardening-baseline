output "policy_id" {
  description = "ID of the created SCP policy"
  value       = aws_organizations_policy.this.id
}
