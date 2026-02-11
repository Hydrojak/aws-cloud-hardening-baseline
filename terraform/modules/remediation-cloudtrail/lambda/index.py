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

            ct.put_event_selectors(TrailName=TRAIL_NAME, EventSelectors=BASE_EVENT_SELECTORS)
            actions.append("put_event_selectors")

            ct.start_logging(Name=TRAIL_NAME)
            actions.append("start_logging_after_update")

        if event_name == "DeleteTrail":
            actions.append("trail_deleted_no_auto_fix")

    except Exception as exc:
        LOG.exception("remediation_failed")
        return {"ok": False, "eventName": event_name, "actions": actions, "error": str(exc)}

    return {"ok": True, "eventName": event_name, "actions": actions}
