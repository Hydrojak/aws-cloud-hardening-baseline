# Hardening Decisions

This project is designed to provide a secure AWS baseline while remaining cost-free.

## Design Principles

- Zero cost (AWS Free Tier compatible)
- Security by default
- Explicit trade-offs documented
- Infrastructure as Code (Terraform)

## Key Decisions

### Why no KMS (Customer Managed Keys)
- AWS KMS can incur costs after the free tier
- SSE-S3 provides sufficient encryption for baseline logging

### Why no GuardDuty or Security Hub
- These services are not fully free
- Detection is planned for a future version (V2)

### Why IAM deny guardrails for S3
- Prevents the most common real-world misconfiguration: public S3 buckets
- Uses explicit deny, which cannot be bypassed by allow policies

### Why single-region CloudTrail
- Reduces log volume and cost
- Sufficient for a learning and baseline project

## Future Improvements

- Replace AdministratorAccess with least-privilege IAM
- Add organization-level SCPs
- Add automated alerting
