# References & Learning Resources

This document lists the **primary references** I used to design and understand the hardening + detection + alerting layers of this project.

Goal: keep the project **transparent**, **auditable**, and easy to study.

---

## AWS — Audit Logging (CloudTrail)

- CloudTrail event reference (event fields, structure, semantics)  
  https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-event-reference.html

- Viewing CloudTrail events / Event history  
  https://docs.aws.amazon.com/awscloudtrail/latest/userguide/view-cloudtrail-events.html

- CloudTrail concepts and configuration  
  https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-user-guide.html

---

## AWS — Event-driven Detection (EventBridge)

- EventBridge event patterns (how matching works)  
  https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-event-patterns.html

- EventBridge rules (concepts and rule behavior)  
  https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-rules.html

---

## AWS — Detection Storage (CloudWatch Logs)

- CloudWatch Logs filter and pattern syntax (metric filters)  
  https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/FilterAndPatternSyntax.html

- Metric filters (turn logs into metrics)  
  https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/MonitoringPolicyExamples.html

- CloudWatch Logs concepts  
  https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/WhatIsCloudWatchLogs.html

---

## AWS — Alerting (CloudWatch Alarms)

- CloudWatch alarms (how thresholds/evaluation works)  
  https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html

- CloudWatch metrics (namespaces, dimensions)  
  https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/working_with_metrics.html

---

## AWS — IAM Hardening

- IAM API operations (understanding high-risk IAM actions)  
  https://docs.aws.amazon.com/IAM/latest/APIReference/API_Operations.html

- IAM user guide (policies, roles, security best practices)  
  https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html

---

## AWS — Access Analyzer

- AWS IAM Access Analyzer  
  https://docs.aws.amazon.com/IAM/latest/UserGuide/what-is-access-analyzer.html

---

## AWS — S3 Guardrails

- S3 Block Public Access  
  https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-control-block-public-access.html

- S3 bucket policies  
  https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucket-policies.html

---

## Threat Modeling & Detection Engineering

- MITRE ATT&CK Cloud Matrix  
  https://attack.mitre.org/matrices/enterprise/cloud/

- MITRE ATT&CK Techniques (mapping actions like credential creation / privilege escalation)  
  https://attack.mitre.org/techniques/enterprise/

---

## Terraform (Infrastructure as Code)

- Terraform documentation (core concepts and CLI workflows)  
  https://developer.hashicorp.com/terraform/docs

- Terraform AWS provider docs (resource behavior and arguments)  
  https://registry.terraform.io/providers/hashicorp/aws/latest/docs


---

## Operational Notes (Local CLI on Windows)

- Git Bash (MSYS) path conversion can rewrite arguments that start with `/` (ex: CloudWatch log group names).
  When using AWS CLI with log groups like `/aws/...`, I may disable path conversion for the command:
  `MSYS_NO_PATHCONV=1 <command>`.
