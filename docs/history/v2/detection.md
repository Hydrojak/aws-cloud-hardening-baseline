# Detection Layer (V2)

This document describes the **detection layer** added in V2 of the AWS Cloud Hardening Baseline.

The goal of this layer is to provide **defensive visibility** into high-risk actions by leveraging **CloudTrail**, **EventBridge**, and **CloudWatch Logs**, while remaining **cost-conscious** and **design-first**.

---

## 🎯 Detection Philosophy

This detection layer is intentionally:

- Passive (no automated response)
- Event-driven (CloudTrail → EventBridge)
- Low-noise (focus on strong security signals)
- Low-cost (short log retention, no SIEM)

It is designed as a **baseline for cloud defense**, not a full SOC or SIEM replacement.

---

## 🧱 Architecture Overview

1. CloudTrail records management API activity
2. EventBridge rules match security-relevant events
3. Matched events are forwarded to a dedicated CloudWatch Log Group
4. Logs can be reviewed manually or used later for alerting

---

## 🔍 Detected Security Signals

### 1️⃣ CloudTrail Tampering

**Detected events:**
- StopLogging
- DeleteTrail
- UpdateTrail
- PutEventSelectors
- PutInsightSelectors

**Why it matters:**  
Disabling or modifying CloudTrail is a common attacker technique to reduce visibility.

---

### 2️⃣ IAM Privilege Escalation Signals

**Detected events:**
- AttachUserPolicy
- AttachRolePolicy
- AttachGroupPolicy
- PutUserPolicy
- PutRolePolicy
- PutGroupPolicy
- CreatePolicy
- CreatePolicyVersion
- SetDefaultPolicyVersion

**Why it matters:**  
Unexpected IAM policy changes may indicate privilege escalation or lateral movement.

---

### 3️⃣ Credential Creation

**Detected events:**
- CreateAccessKey
- CreateLoginProfile
- UpdateLoginProfile

**Why it matters:**  
New credentials may signal persistence after account compromise.

---

### 4️⃣ S3 Exposure Attempts

**Detected events:**
- PutBucketAcl
- PutBucketPolicy
- DeleteBucketPolicy
- PutBucketPublicAccessBlock

**Why it matters:**  
S3 misconfigurations are a leading cause of cloud data exposure.

---

## 📊 Log Management

- Detection events are sent to a dedicated CloudWatch Log Group
- Log retention is intentionally short (7 days) to control costs
- Logs remain structured CloudTrail events

---

## 🚫 Out of Scope

This detection layer does NOT include:

- Real-time alerting
- Automated remediation
- Event correlation
- Anomaly-based detection
- SIEM integration

---

## ⚠️ Known Limitations

- CloudTrail delivery latency
- Potential noise in high-activity accounts
- Pattern-based detection only
- No context-aware validation

---

## 🛣️ Future Improvements

- CloudWatch alarms
- SNS alerting
- Lambda-based remediation
- Organization-wide detections
- External SIEM integration

---

## ✅ Summary

This detection layer provides a **pragmatic starting point for cloud defense**:

- PutGroupPolicy
- CreatePolicy
- CreatePolicyVersion
- SetDefaultPolicyVersion

**Why it matters:**  
Unexpected IAM policy changes may indicate privilege escalation or lateral movement.

---

### 3️⃣ Credential Creation

**Detected events:**
- CreateAccessKey
- CreateLoginProfile
- UpdateLoginProfile

**Why it matters:**  
New credentials may signal persistence after account compromise.

---

### 4️⃣ S3 Exposure Attempts

**Detected events:**
- PutBucketAcl
- PutBucketPolicy
- DeleteBucketPolicy
- PutBucketPublicAccessBlock

**Why it matters:**  
S3 misconfigurations are a leading cause of cloud data exposure.

---

## 📊 Log Management

- Detection events are sent to a dedicated CloudWatch Log Group
- Log retention is intentionally short (7 days) to control costs
- Logs remain structured CloudTrail events

---

## 🚫 Out of Scope

This detection layer does NOT include:

- Real-time alerting
- Automated remediation
- Event correlation
- Anomaly-based detection
- SIEM integration

---

## ⚠️ Known Limitations

- CloudTrail delivery latency
- Potential noise in high-activity accounts
- Pattern-based detection only

- CloudTrail delivery latency
- Potential noise in high-activity accounts
- Pattern-based detection only
- No context-aware validation

---

## 🛣️ Future Improvements

- CloudWatch alarms
- SNS alerting
- Lambda-based remediation
- Organization-wide detections
- External SIEM integration

---

## ✅ Summary

This detection layer provides a **pragmatic starting point for cloud defense**:
simple, cost-aware, and focused on high-risk actions.
