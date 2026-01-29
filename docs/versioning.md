# Project Versioning

This project follows an incremental versioning approach.

- **V1**  
  Preventive hardening baseline (IAM, CloudTrail, S3 guardrails)

- **V2.1**  
  Detection layer using CloudTrail, EventBridge, and CloudWatch Logs

- **V2.1.2**  
  Documentation, validation, and clarity improvements

- **V2.2 (planned)**  
  Alerting on high-risk events (CloudWatch Alarms / SNS)

## Project scope and validation

This project is designed as a **security baseline and portfolio project**.

- The Terraform code is fully deployable on a real AWS account.
- The baseline has been tested in laboratory environments.
- The project is intentionally scoped and does not claim production readiness.

The primary goals are:
- demonstrate cloud security hardening practices
- show detection logic and alerting design
- remain auditable and cost-aware

The code can be statically validated without AWS access, but meaningful security
testing requires deployment in a real AWS account.
