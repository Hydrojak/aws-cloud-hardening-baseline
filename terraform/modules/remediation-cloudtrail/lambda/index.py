"""Reconcile one explicitly owned trail. AWS clients are created only in the handler."""
import json
import logging
import os

LOG = logging.getLogger()
LOG.setLevel(logging.INFO)


def normalized(selectors):
    """CloudTrail can reorder selectors and include empty optional fields."""
    result = []
    for item in selectors:
        resources = sorted((r["Type"], sorted(r["Values"])) for r in item.get("DataResources", []))
        result.append((item["ReadWriteType"], item["IncludeManagementEvents"],
                       sorted(item.get("ExcludeManagementEventSources", [])), resources))
    return sorted(result)


def reconcile(client, event, cfg):
    arn = cfg["TRAIL_ARN"]
    scheduled = event.get("source") == "aws.events" and event.get("detail-type") == "Scheduled Event"
    detail = event.get("detail", {})
    if not scheduled:
        params = detail.get("requestParameters") or {}
        issuer = detail.get("userIdentity", {}).get("sessionContext", {}).get("sessionIssuer", {}).get("arn")
        if (event.get("source") != "aws.cloudtrail" or detail.get("eventSource") != "cloudtrail.amazonaws.com"
                or event.get("account") != arn.split(":")[4] or event.get("region") != cfg["HOME_REGION"]
                or detail.get("errorCode") or issuer == cfg["ROLE_ARN"]
                or (params.get("name") or params.get("trailName")) not in {arn, arn.split("/")[-1]}):
            return "ignored"
        if detail.get("eventName") not in {"DeleteTrail", "StopLogging", "UpdateTrail", "PutEventSelectors", "PutInsightSelectors"}:
            return "ignored"
        if detail["eventName"] in {"DeleteTrail", "PutInsightSelectors"}:
            raise RuntimeError("Operator review required: " + detail["eventName"])

    trail = client.get_trail(Name=arn)["Trail"]
    status = client.get_trail_status(Name=arn)
    selected = client.get_event_selectors(TrailName=arn)
    expected = json.loads(cfg["EXPECTED_FLAGS"])
    selectors = json.loads(cfg["EXPECTED_SELECTORS"])
    response_keys = {"EnableLogFileValidation": "LogFileValidationEnabled"}
    changes = {k: v for k, v in expected.items() if trail.get(response_keys.get(k, k)) != v}
    # Changing organization membership or replacing an advanced selector needs an operator.
    if (selected.get("AdvancedEventSelectors") or trail.get("S3KeyPrefix")
            or bool(trail.get("IsOrganizationTrail")) != (cfg["ORG_TRAIL"] == "true")
            or (not expected.get("KmsKeyId") and trail.get("KmsKeyId"))):
        raise RuntimeError("Unmanaged trail configuration requires review")
    selector_drift = normalized(selectors) != normalized(selected.get("EventSelectors", []))
    if changes or selector_drift or not status["IsLogging"]:
        if cfg["REPAIR"] != "true":
            raise RuntimeError("Trail drift detected in monitor-only mode")
        if changes:
            client.update_trail(Name=arn, **changes)
        if selector_drift:
            client.put_event_selectors(TrailName=arn, EventSelectors=selectors)
        if not status["IsLogging"]:
            client.start_logging(Name=arn)
        LOG.info("trail_repair_requested")
    if status.get("LatestDeliveryError") or status.get("LatestDigestDeliveryError"):
        raise RuntimeError("CloudTrail reports a delivery error")
    if scheduled:
        LOG.info("scheduled_check_completed")
    return "checked"


def handler(event, context):
    import boto3
    return reconcile(boto3.client("cloudtrail", region_name=os.environ["HOME_REGION"]), event, os.environ)
