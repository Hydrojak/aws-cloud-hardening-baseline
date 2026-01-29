# Detection Testing – AWS Cloud Hardening Baseline

This document explains **how to safely test security detections** implemented by the AWS Cloud Hardening Baseline.

The goal is to verify that:
- CloudTrail logs events correctly
- EventBridge rules detect risky actions
- CloudWatch Logs and Alarms react as expected

Tests should be performed in a **non-production environment**.

---

## 1. General Testing Principles

- Always use a **dedicated test AWS account or workspace**
- Prefer **temporary IAM users or roles**
- Revert all changes after testing
- Monitor CloudWatch Logs in real time during tests

---

## 2. Verify Logging Pipeline

### 2.1 Check CloudTrail Status

```
aws cloudtrail describe-trails
aws cloudtrail get-trail-status --name <trail-name>
```

Expected result:
- `IsLogging: true`
- No delivery errors

---

### 2.2 Verify CloudWatch Log Group

```
aws logs describe-log-groups
```

Expected log group:
```
/aws/cloud-hardening-baseline/detections
```

---

## 3. Detection Test Scenarios

---

### 3.1 Test: CloudTrail Tampering Detection

**Purpose**  
Verify detection of CloudTrail disable attempts.

**Test Command**

```
aws cloudtrail stop-logging --name <trail-name>
```

**Expected Result**
- Event appears in CloudWatch Logs
- CloudWatch Alarm triggers
- Optional SNS notification is sent

**Cleanup**

```
aws cloudtrail start-logging --name <trail-name>
```

---

### 3.2 Test: IAM Policy Change Detection

**Purpose**  
Detect privilege escalation attempts.

**Test Command**

```
aws iam attach-user-policy \
--user-name test-user \
--policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

**Expected Result**
- Event detected and logged
- Alarm triggered

**Cleanup**

```
aws iam detach-user-policy \
--user-name test-user \
--policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

---

### 3.3 Test: Access Key Creation Detection

**Purpose**  
Detect new credential creation.

**Test Command**

```
aws iam create-access-key --user-name test-user
```

**Expected Result**
- Credential creation logged
- Detection event visible

**Cleanup**

```
aws iam delete-access-key \
--user-name test-user \
--access-key-id <key-id>
```

---

### 3.4 Test: S3 Public Exposure Detection

**Purpose**  
Verify detection of public S3 exposure attempts.

**Test Command**

```
aws s3api put-bucket-acl \
--bucket <bucket-name> \
--acl public-read
```

**Expected Result**
- Action blocked or detected
- Event logged in CloudWatch
- Alarm triggered

**Cleanup**

```
aws s3api put-bucket-acl \
--bucket <bucket-name> \
--acl private
```

---

## 4. EventBridge Rule Validation

### Send a Custom Test Event (Optional)

```
aws events put-events --entries file://test-event.json
``````

Expected result:
- Event appears in CloudWatch Logs
- Rule matches expected pattern

---

## 5. Troubleshooting Failed Detections

| Issue | Possible Cause | Resolution |
|-----|---------------|------------|
| No logs | CloudTrail disabled | Re-enable CloudTrail |
| No alert | Alarm misconfigured | Check metric filters |
| Delay | EventBridge latency | Wait up to a few minutes |

---

## 6. Post-Test Checklist

- Revert IAM changes
- Delete test users or credentials
- Restore original configurations
- Confirm baseline is fully operational

---

## Conclusion

Detection testing ensures that:
- Security controls work as intended
- Alerts are reliable
- The environment is ready for real incidents

Regular testing is recommended after:
- Infrastructure changes
- Terraform updates
- AWS account modifications

---
