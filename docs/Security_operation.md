# Security Operations – AWS Cloud Hardening Baseline

This document describes **how to operate, monitor, and respond** to security events detected by the AWS Cloud Hardening Baseline.

It focuses on **incident detection, analysis, response, and recovery** using the services deployed by this project.

---

## 1. Security Monitoring Overview

The baseline provides three core security layers:

- **Prevention**  
  Guardrails to block dangerous configurations (e.g. public S3 access).

- **Detection**  
  CloudTrail logs + EventBridge rules to detect suspicious or high-risk actions.

- **Alerting**  
  CloudWatch Alarms with optional SNS notifications.

---

## 2. Log Sources

### 2.1 CloudTrail

CloudTrail records all **management API events**, including:
- IAM policy changes
- Credential creation
- CloudTrail configuration changes
- S3 bucket policy and ACL updates

**Log storage**
- Encrypted S3 bucket
- Versioning enabled
- Public access blocked
- Optional lifecycle policies for cost control

### 2.2 CloudWatch Logs

Detected events are forwarded to a dedicated log group:
```
/aws/cloud-hardening-baseline/detections
```

Logs are retained based on the configured retention period.

---

## 3. Alerting Mechanism

Alerts are generated using **CloudWatch Alarms** based on:
- Matching EventBridge security rules
- Metric filters on sensitive actions

Optional alert delivery:
- Amazon SNS (email notifications)
- CloudWatch dashboard visibility

---

## 4. Incident Detection Scenarios

### 4.1 CloudTrail Tampering

**Description**  
Attempts to disable or modify CloudTrail logging.

**Example Events**
- `StopLogging`
- `DeleteTrail`
- `UpdateTrail`

**Risk**
- Loss of audit logs
- Reduced forensic capability

**Response**
1. Verify CloudTrail status.
2. Identify the IAM principal responsible.
3. Re-enable CloudTrail immediately.
4. Rotate credentials if compromise is suspected.

---

### 4.2 IAM Policy or Credential Changes

**Description**  
Detection of privilege escalation or credential creation.

**Example Events**
- `CreateAccessKey`
- `AttachRolePolicy`
- `PutUserPolicy`

**Risk**
- Unauthorized access
- Privilege escalation

**Response**
1. Identify the affected user or role.
2. Review policy changes.
3. Disable or delete suspicious credentials.
4. Audit recent activity of the principal.

---

### 4.3 S3 Public Exposure Attempts

**Description**  
Attempts to make an S3 bucket public.

**Example Events**
- `PutBucketPolicy`
- `PutBucketAcl`
- `DeletePublicAccessBlock`

**Risk**
- Data exposure or leakage

**Response**
1. Verify bucket configuration.
2. Restore Public Access Block if modified.
3. Review bucket access logs.
4. Assess data exposure impact.

---

## 5. Incident Response Workflow

### Step 1 – Alert Received
- CloudWatch Alarm triggers
- Optional SNS notification received

### Step 2 – Event Analysis
- Review CloudWatch Logs event
- Identify:
    - Action performed
    - Source IP
    - IAM principal
    - Timestamp

### Step 3 – Containment
- Disable affected IAM credentials
- Revert unauthorized configuration changes
- Restrict access if needed

### Step 4 – Eradication
- Remove malicious policies or resources
- Patch misconfigurations
- Rotate credentials

### Step 5 – Recovery
- Restore normal operations
- Validate security baseline status
- Confirm logging and alerting are active

---

## 6. Post-Incident Actions

- Document the incident:
    - Root cause
    - Timeline
    - Impact
    - Corrective actions
- Update Terraform configuration if needed
- Improve detection rules if gaps are identified

---

## 7. Operational Best Practices

- Regularly review CloudTrail and detection logs
- Test alerting mechanisms periodically
- Limit IAM privileges using least privilege
- Protect Terraform state files
- Avoid manual changes outside Terraform

---

## 8. Security Scope & Limitations

This baseline:
- Covers **management plane security**
- Does NOT replace:
    - Network security monitoring
    - Application-level security
    - Advanced threat detection services (GuardDuty, Security Hub)

It is designed as a **lightweight security foundation**, not a full SOC solution.

---

## Conclusion

The AWS Cloud Hardening Baseline enables:
- Faster detection of security incidents
- Clear response procedures
- Improved audit readiness
- Stronger cloud security posture with minimal complexity

---
