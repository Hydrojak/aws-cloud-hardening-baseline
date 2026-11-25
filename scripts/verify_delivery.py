"""Prove cross-region delivery with custom probe events; never modify a security control."""
import argparse
import datetime as dt
import json
import subprocess
import time
import uuid
from pathlib import Path


def aws(profile, region, *args):
    result = subprocess.run(["aws", "--no-cli-pager", "--output", "json", "--profile", profile,
                             "--region", region, *args], text=True, capture_output=True)
    if result.returncode:
        raise RuntimeError(result.stderr.strip())
    return json.loads(result.stdout or "{}")


def poll(read, deadline, label):
    while time.monotonic() < deadline:
        value = read()
        if value:
            return value
        time.sleep(8)
    raise TimeoutError(label)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("source-profile", "security-profile","source-account","security-account","sns-topic","output"):
        parser.add_argument("--" + name, required=True)
    parser.add_argument("--central-region",default="eu-west-1")
    parser.add_argument("--regions",nargs="+",default=["eu-west-1","us-east-1"])
    parser.add_argument("--timeout",type=int,default=600)
    args = parser.parse_args()
    central = lambda *a: aws(args.security_profile,args.central_region,*a)
    regions = list(dict.fromkeys(args.regions))
    now = dt.datetime.now(dt.timezone.utc)
    nonce = str(uuid.uuid4())
    report = {"started_utc":now.isoformat(), "probe":nonce,"deliveries":{},
              "mailbox_receipt":"manual verification pending","result":"failed"}
    output = Path(args.output)
    output.parent.mkdir(parents=True,exist_ok=True)
    try:
        if len(regions)<2 or "us-east-1" not in regions:
            raise ValueError("Supply at least two regions, including us-east-1")
        source_id = aws(args.source_profile,regions[0],"sts","get-caller-identity")["Account"]
        if source_id != args.source_account or central("sts","get-caller-identity")["Account"] != args.security_account:
            raise ValueError("AWS profile/account mismatch")
        report["source_account"] = source_id
        subs = central("sns","list-subscriptions-by-topic","--topic-arn",args.sns_topic)["Subscriptions"]
        if not any(s["Protocol"]=="email" and s["SubscriptionArn"].startswith("arn:") for s in subs):
            raise RuntimeError("No confirmed email subscription")
        alarm = "baseline-security-pipeline-probe"
        existing = central("cloudwatch","describe-alarms","--alarm-names",alarm)["MetricAlarms"]
        if len(existing)!=1 or args.sns_topic not in existing[0]["AlarmActions"] or not existing[0]["ActionsEnabled"]:
            raise RuntimeError("Alarm missing, disabled or configured for another topic")
        if existing[0]["StateValue"]=="ALARM":
            raise RuntimeError("Wait for the preceding probe alarm to return to OK, then retry")
        for region in regions:
            entry = {"Source":"baseline.health","DetailType":"Baseline delivery probe",
                     "Detail":json.dumps({"probe":nonce,"region":region})}
            sent = aws(args.source_profile,region,"events","put-events","--entries",json.dumps([entry]))
            if sent["FailedEntryCount"]: raise RuntimeError("PutEvents failed: "+str(sent["Entries"]))
            report["deliveries"][region]={"submitted_id":sent["Entries"][0]["EventId"]}
        deadline = time.monotonic()+args.timeout
        for region in regions:
            def evidence():
                found = central("logs","filter-log-events","--log-group-name","/aws/events/baseline-security",
                                "--start-time",str(int(now.timestamp()*1000)-5000),
                                "--filter-pattern",'{ $.detail.probe = "'+nonce+'" }')
                for row in found["events"]:
                    event=json.loads(row["message"])
                    if event["account"]==source_id and event["detail"].get("region")==region and event.get("region")==region:
                        return {"log_event_id":row["eventId"],"timestamp_ms":row["timestamp"]}
            report["deliveries"][region].update(poll(evidence,deadline,"missing central log from "+region))
        def action():
            history=central("cloudwatch","describe-alarm-history","--alarm-name",alarm,"--history-item-type","Action",
                            "--start-date",now.isoformat())["AlarmHistoryItems"]
            for item in history:
                data=json.loads(item["HistoryData"])
                if data.get("actionState")=="Succeeded" and args.sns_topic in (data.get("notificationResource") or item.get("HistorySummary","")):
                    return item["Timestamp"]
        report["alarm_action_utc"]=poll(action,deadline,"missing successful SNS alarm action")
        report["result"]="passed to SNS"
    finally:
        output.write_text(json.dumps(report,indent=2)+"\n")
    print("Passed to SNS. Record receipt in the recipient's mailbox separately.")

if __name__=="__main__":
    main()
