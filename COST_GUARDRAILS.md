# Cost Guardrails

This document explains the **cost-related design decisions** made in this project.

The goal is to demonstrate a **cloud security baseline** that remains **usable, auditable, and affordable**, especially for learning, testing, and small environments.

---

## 🎯 Cost Control Objectives

- Keep the baseline compatible with AWS Free Tier whenever possible
- Avoid services with unpredictable or high recurring costs
- Prefer event-driven and serverless components
- Maintain visibility without over-collecting data

---

## 🧱 Services Explicitly Used (Low / Predictable Cost)

### AWS CloudTrail
- Management events only
- Single-region trail
- Logs stored in S3 (low storage cost)
- No data events enabled

**Reasoning:**  
CloudTrail is essential for auditability and security visibility. Management events provide high value at minimal cost.

---

### Amazon S3 (Log Storage)
- Single bucket for centralized logging
- Versioning enabled
- Public access fully blocked
- No lifecycle transitions to other storage classes

**Reasoning:**  
S3 is cost-effective for log storage and allows long-term retention if needed.

---

### Amazon EventBridge
- Event-based detections
- No polling or persistent compute
- Only high-signal CloudTrail events are matched

**Reasoning:**  
EventBridge provides near real-time detection at very low cost compared to continuous log scanning.

---

### Amazon CloudWatch Logs
- Dedicated log group for detection events
- Short retention period (7 days)
- Logs only include security-relevant events

**Reasoning:**  
Short retention reduces storage costs while preserving immediate forensic visibility.

---

### Amazon CloudWatch Metrics & Alarms
- Custom metrics generated from detection logs
- Simple threshold-based alarms
- No notifications configured by default

**Reasoning:**  
Metrics and alarms provide visibility with minimal ongoing cost.

---

## 🚫 Services Intentionally Excluded (Cost-Avoidance)

The following services were intentionally not enabled in this baseline:

- **GuardDuty**
- **Security Hub**
- **VPC Flow Logs**
- **NAT Gateways**
- **EC2 / EKS / RDS**
- **OpenSearch / Elasticsearch**
- **AWS Config**

**Reasoning:**  
These services can generate significant costs and are better introduced after a baseline is validated and operational needs are clearly defined.

---

## 🧠 Cost-Security Trade-offs

- High-signal detections were preferred over exhaustive coverage
- Short log retention favors cost efficiency over long-term forensics
- No automated remediation or notifications to avoid unintended costs
- The baseline is designed for **learning, demonstration, and small-scale environments**

---

## ⚠️ Cost Awareness Notes

- CloudTrail log volume increases with account activity
- CloudWatch Logs and metrics generate costs proportional to usage
- Alarms incur minor monthly charges
- Costs should be monitored if extended to production environments

---

## ✅ Summary

This project demonstrates that a **useful cloud security baseline** can be implemented without relying on expensive managed services.

Cost control is treated as a **security requirement**, not an afterthought.
