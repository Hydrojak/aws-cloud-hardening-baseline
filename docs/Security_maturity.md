# Security Maturity Model – AWS Cloud Hardening Baseline

This document positions the AWS Cloud Hardening Baseline within a **cloud security maturity model**.

It explains:
- What level of security this project provides
- What risks are addressed
- What is intentionally out of scope

---

## 1. Security Maturity Levels

| Level | Name | Description |
|-----|------|-------------|
| 0 | No Security | No logging, no monitoring, no controls |
| 1 | Basic Visibility | Logs enabled, limited awareness |
| 2 | Preventive Controls | Guardrails and misconfiguration prevention |
| 3 | Detective Controls | Detection and alerting |
| 4 | Reactive Security | Incident response processes |
| 5 | Proactive Security | Threat intelligence and automation |

---

## 2. Target Level of This Project

The AWS Cloud Hardening Baseline targets **Levels 2–4**:

- **Level 2 – Preventive Controls**
    - S3 Public Access Block
    - IAM guardrails
    - Secure defaults

- **Level 3 – Detective Controls**
    - CloudTrail logging
    - EventBridge security rules
    - CloudWatch Logs and Alarms

- **Level 4 – Reactive Security**
    - Incident response playbooks
    - Operational procedures
    - Manual remediation workflows

---

## 3. Security Capabilities Provided

### 3.1 Prevention

- Blocks public S3 exposure
- Prevents accidental security misconfigurations
- Enforces baseline security settings via Terraform

---

### 3.2 Detection

- Detects CloudTrail tampering
- Detects IAM privilege escalation
- Detects credential creation
- Detects S3 exposure attempts

---

### 3.3 Alerting

- CloudWatch Alarms
- Optional SNS notifications
- Centralized alert visibility

---

### 3.4 Response Readiness

- Defined incident response steps
- Forensic-ready logs
- Clear ownership for remediation

---

## 4. Out of Scope (Explicit Limitations)

This project intentionally does **NOT** include:

- Network-level threat detection
- Application security monitoring
- Malware detection
- Runtime workload protection
- Advanced AWS services such as:
    - GuardDuty
    - Security Hub
    - Inspector
    - Macie

These services are excluded to:
- Keep costs low
- Reduce complexity
- Maintain full Terraform control

---

## 5. Why This Scope Makes Sense

This baseline is designed for:
- Small to medium AWS environments
- Educational or proof-of-concept projects
- Organizations starting their cloud security journey

It provides **maximum security value with minimal operational overhead**.

---

## 6. Security Evolution Path

The baseline can be extended to higher maturity levels:

| Future Improvement | Target Level |
|-------------------|--------------|
| GuardDuty integration | Level 5 |
| Automated remediation (Lambda) | Level 5 |
| SOAR workflows | Level 5 |
| Security dashboards | Level 4–5 |

---

## 7. Key Takeaways

- This project establishes a **strong security foundation**
- It enforces **security by default**
- It improves **visibility and response readiness**
- It clearly defines its **limits and assumptions**

---

## Conclusion

The AWS Cloud Hardening Baseline represents a **pragmatic and realistic security maturity step**.

It bridges the gap between:
- No security controls
- And full enterprise-grade cloud security platforms

While remaining lightweight, transparent, and cost-effective.

---
