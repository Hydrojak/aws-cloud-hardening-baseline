variable "bus_arn" { type = string }
variable "source_accounts" {
  type = set(string)
  validation {
    condition     = length(var.source_accounts) > 0 && alltrue([for id in var.source_accounts : can(regex("^[0-9]{12}$", id))])
    error_message = "Provide at least one exact AWS account ID."
  }
}
variable "organization_id" {
  type = string
  validation {
    condition     = can(regex("^o-[a-z0-9]{10,32}$", var.organization_id))
    error_message = "Supply an exact organization ID."
  }
}
output "policy" {
  value = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "ListedOrganizationSenders"
      Effect    = "Allow"
      Principal = { AWS = [for id in sort(var.source_accounts) : "arn:aws:iam::${id}:root"] }
      Action    = "events:PutEvents"
      Resource  = var.bus_arn
      Condition = {
        StringEquals = { "aws:PrincipalOrgID" = var.organization_id }
        Bool         = { "events:eventBusInvocation" = "true" }
        ArnLike      = { "aws:PrincipalArn" = [for id in sort(var.source_accounts) : "arn:aws:iam::${id}:role/baseline-event-forward-*"] }
      }
    }]
  })
}
