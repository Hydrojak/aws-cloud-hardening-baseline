# CIS AWS Foundations Benchmark – Mapping

This document maps the implemented Terraform controls to the CIS AWS Foundations Benchmark.

## Identity and Access Management (IAM)

- **1.1** Ensure IAM password policy requires strong passwords  
  ✅ Implemented (`iam-baseline`)

- **1.2** Ensure IAM password policy prevents password reuse  
  ✅ Implemented (`iam-baseline`)

- **1.3** Ensure IAM password policy expires passwords within 90 days  
  ✅ Implemented (`iam-baseline`)

- **1.5** Ensure IAM Access Analyzer is enabled  
  ✅ Implemented (`iam-baseline`)

## Logging and Monitoring

- **2.1** Ensure CloudTrail is enabled in at least one region  
  ✅ Implemented (`cloudtrail-logging`)

- **2.2** Ensure CloudTrail log file validation is enabled  
  ✅ Implemented (`cloudtrail-logging`)

- **2.3** Ensure CloudTrail logs are encrypted at rest  
  ✅ Implemented (SSE-S3)

## S3 Security

- **3.1** Ensure S3 buckets are not publicly accessible  
  ✅ Implemented (`cloudtrail-logging`, `s3-guardrails`)

- **3.2** Ensure S3 Block Public Access is enabled  
  ✅ Implemented (`cloudtrail-logging`, `s3-guardrails`)

## Not Implemented (Planned)

- GuardDuty
- Security Hub
- VPC Flow Logs

Reason: cost control (Free Tier / lab context).
