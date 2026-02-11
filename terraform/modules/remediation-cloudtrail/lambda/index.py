import json
import logging
import os
import boto3

LOG = logging.getLogger()
LOG.setLevel(logging.INFO)

TRAIL_NAME = os.environ.get("TRAIL_NAME", "")
HOME_REGION = os.environ.get("HOME_REGION")
IS_MULTI_REGION = os.environ.get("IS_MULTI_REGION_TRAIL", "true").lower() == "true"
LOG_BUCKET_NAME = os.environ.get("LOG_BUCKET_NAME") or None
KMS_KEY_ID = os.environ.get("KMS_KEY_ID") or None
S3_DATA_EVENT_BUCKET_ARNS_JSON = os.getenv("S3_DATA_EVENT_BUCKET_ARNS_JSON", "[]")
LAMBDA_DATA_EVENT_FUNCTION_ARNS_JSON = os.getenv("LAMBDA_DATA_EVENT_FUNCTION_ARNS_JSON", "[]")
DATA_EVENTS_READ_WRITE_TYPE = os.getenv("DATA_EVENTS_READ_WRITE_TYPE", "All")

BASE_EVENT_SELECTORS = [
    {
        "ReadWriteType": "All",
        "IncludeManagementEvents": True,
        # No data events by default (cost-conscious baseline)
    }
]

def _ct_client():
    # CloudTrail is regional; use the trail's home region.
    # If HOME_REGION isn't set, boto3 will fall back to the Lambda's AWS_REGION.
    return boto3.client("cloudtrail", region_name=HOME_REGION)
def _load_json_list(v):
    try:
        data = json.loads(v)
        return data if isinstance(data, list) else []
    except Exception:
        return []

def _build_baseline_event_selectors():
    selectors = [{
        "ReadWriteType": "All",
        "IncludeManagementEvents": True,
    }]

    s3_arns = _load_json_list(S3_DATA_EVENT_BUCKET_ARNS_JSON)
    lambda_arns = _load_json_list(LAMBDA_DATA_EVENT_FUNCTION_ARNS_JSON)

    s3_values = [arn if arn.endswith("/") else arn + "/" for arn in s3_arns if isinstance(arn, str) and arn]
    lambda_values = [arn for arn in lambda_arns if isinstance(arn, str) and arn]

    if not s3_values and not lambda_values:
        return selectors

    rw = DATA_EVENTS_READ_WRITE_TYPE if DATA_EVENTS_READ_WRITE_TYPE in {"All", "ReadOnly", "WriteOnly"} else "All"

    data_resources = []
    if s3_values:
        data_resources.append({"Type": "AWS::S3::Object", "Values": s3_values})
    if lambda_values:
        data_resources.append({"Type": "AWS::Lambda::Function", "Values": lambda_values})

    selectors.append({
        "ReadWriteType": rw,
        "IncludeManagementEvents": False,
        "DataResources": data_resources,
    })
    return selectors

def handler(event, context):
    """EventBridge -> Lambda entry point.

    Conservative remediation:
    - StopLogging -> StartLogging
    - UpdateTrail/PutEventSelectors/PutInsightSelectors -> re-apply baseline flags + event selectors
    - DeleteTrail -> only log (safe recreate is non-trivial)
    """
    LOG.info("received_event=%s", json.dumps(event))

    if not TRAIL_NAME:
        return {"ok": False, "error": "TRAIL_NAME env var is empty"}

    detail = event.get("detail", {}) or {}
    event_source = detail.get("eventSource")
    event_name = detail.get("eventName")

    if event_source != "cloudtrail.amazonaws.com":
        return {"ok": True, "ignored": True, "reason": "not cloudtrail"}

    ct = _ct_client()
    actions = []

    try:
        if event_name == "StopLogging":
            ct.start_logging(Name=TRAIL_NAME)
            actions.append("start_logging")

        if event_name in {"UpdateTrail", "PutEventSelectors", "PutInsightSelectors"}:
            update_kwargs = {
                "Name": TRAIL_NAME,
                "IncludeGlobalServiceEvents": True,
                "IsMultiRegionTrail": IS_MULTI_REGION,
                "EnableLogFileValidation": True,
            }
            if LOG_BUCKET_NAME:
                update_kwargs["S3BucketName"] = LOG_BUCKET_NAME
            if KMS_KEY_ID:
                update_kwargs["KmsKeyId"] = KMS_KEY_ID

            ct.update_trail(**update_kwargs)
            actions.append("update_trail")

            selectors = _build_baseline_event_selectors()
            ct.put_event_selectors(TrailName=TRAIL_NAME, EventSelectors=selectors)
            actions.append("put_event_selectors")
            LOG.info("applying_event_selectors=%s", json.dumps(selectors))


            ct.start_logging(Name=TRAIL_NAME)
            actions.append("start_logging_after_update")

        if event_name == "DeleteTrail":
            actions.append("trail_deleted_no_auto_fix")

    except Exception as exc:
        LOG.exception("remediation_failed")
        return {"ok": False, "eventName": event_name, "actions": actions, "error": str(exc)}

    return {"ok": True, "eventName": event_name, "actions": actions}
