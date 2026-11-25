# User Stories – AWS Cloud Hardening Baseline

This document describes the main **user stories** of the project from three different perspectives:
- Business / Management (non-technical)
- Developer
- IT / Cloud Administrator

The goal is to clearly explain the **business value**, **technical value**, and **operational value** of the AWS Cloud Hardening Baseline.

---

## 1. User Story – Business / Management (Non-Technical)

### Description
**As a** business manager or executive,  
**I want** to deploy a simple and standardized AWS security baseline,  
**so that** cloud risks (human error, data exposure, malicious actions) are reduced, security incidents are detected early, and visibility is improved without significantly increasing costs.

### Value
- Reduced cloud security risk
- Improved visibility and auditability
- Faster incident detection and response
- Cost-efficient security foundation

### Acceptance Criteria
- Critical AWS actions are logged and centralized.
- High-risk events trigger alerts.
- The solution is easy to deploy and reusable.
- Security is improved without relying on expensive managed services.

---

## 2. User Story – Developer

### Description
**As a** developer,  
**I want** to integrate an AWS security baseline using Terraform,  
**so that** infrastructure is secure by default and common misconfigurations (public S3 buckets, overly permissive IAM policies, missing logs) are avoided.

### Value
- Security-by-default infrastructure
- Reduced configuration errors
- Clear and reusable Terraform modules
- Easy customization through variables

### Acceptance Criteria
- The baseline can be deployed using standard Terraform commands.
- Modules are logically separated and readable.
- Key parameters are configurable via `terraform.tfvars`.
- Security events are visible in CloudWatch Logs.

---

## 3. User Story – IT / Cloud Administrator

### Description
**As an** IT or Cloud Operations administrator,  
**I want** to deploy a security baseline that prevents dangerous actions and detects suspicious behavior,  
**so that** a minimum security level is enforced, audits are simplified, and incidents can be handled quickly.

### Value
- Automated cloud hardening
- Centralized logging for audits and forensics
- Detection of risky or malicious actions
- Actionable alerts for operations teams

### Acceptance Criteria
- CloudTrail is enabled and logs are stored in a secured S3 bucket.
- S3 buckets are protected against public exposure.
- Security events are detected using EventBridge.
- Alerts are available in CloudWatch and optionally sent via SNS.
- Log retention is configurable.

---

## Conclusion

This project provides:
- **Prevention**: IAM and S3 guardrails
- **Detection**: CloudTrail and EventBridge security events
- **Alerting**: CloudWatch Alarms with optional SNS notifications

It serves as a **lightweight, automated security foundation** for small to medium AWS environments.
