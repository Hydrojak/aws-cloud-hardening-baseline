"""Check trail health, real log delivery, version retention and restore a version in a pilot."""
import argparse
import gzip
import hashlib
import tempfile
import datetime as dt
import json
import subprocess
from pathlib import Path
from verify_delivery import aws

p=argparse.ArgumentParser(description=__doc__)
for key in ("management-profile","archive-profile","management-account","archive-account","member-account","organization","trail","bucket","output"):
    p.add_argument("--"+key,required=True)
p.add_argument("--region",default="eu-west-1")
args=p.parse_args()
m=lambda *x:aws(args.management_profile,args.region,*x)
a=lambda *x:aws(args.archive_profile,args.region,*x)
def require(value,message):
    if not value: raise RuntimeError(message)
require(m("sts","get-caller-identity")["Account"]==args.management_account,"Incorrect management profile")
require(a("sts","get-caller-identity")["Account"]==args.archive_account,"Incorrect archive profile")
trail=m("cloudtrail","get-trail","--name",args.trail)["Trail"]
require(all(trail.get(k) for k in ("IsMultiRegionTrail","IsOrganizationTrail","LogFileValidationEnabled")) and trail["S3BucketName"]==args.bucket,"Trail configuration mismatch")
status=m("cloudtrail","get-trail-status","--name",trail["TrailARN"])
require(status["IsLogging"] and not status.get("LatestDeliveryError") and not status.get("LatestDigestDeliveryError"),"Trail stopped or delivery failed")
bucket=["--bucket",args.bucket,"--expected-bucket-owner",args.archive_account]
require(a("s3api","get-bucket-versioning",*bucket)["Status"]=="Enabled","Versioning not enabled")
require(all(a("s3api","get-public-access-block",*bucket)["PublicAccessBlockConfiguration"].values()),"BPA disabled")
retention=a("s3api","get-object-lock-configuration",*bucket)["ObjectLockConfiguration"]["Rule"]["DefaultRetention"]
require(retention["Mode"] in ("GOVERNANCE","COMPLIANCE") and retention.get("Days",0)>0,"Retention missing")
now=dt.datetime.now(dt.timezone.utc)
prefix=f"AWSLogs/{args.organization}/{args.member_account}/CloudTrail/{args.region}/"
objects=[]
for day in (now,now-dt.timedelta(days=1)):
    result=a("s3api","list-objects-v2",*bucket,"--prefix",prefix+day.strftime("%Y/%m/%d/"),"--max-items","1000")
    objects.extend(result.get("Contents",[]))
require(objects,"No recent member log. Generate normal activity and allow delivery time.")
latest=max(objects,key=lambda o:o["LastModified"])
require(dt.datetime.fromisoformat(latest["LastModified"].replace("Z","+00:00"))>now-dt.timedelta(hours=24),"No log newer than 24 hours")
# Verify actual object retention, not just the bucket's current defaults.
head=a("s3api","head-object",*bucket,"--key",latest["Key"])
require(head.get("ObjectLockMode") in ("GOVERNANCE","COMPLIANCE") and head.get("VersionId"),"Object not versioned/locked")
proof=dict(trail=trail["TrailARN"],last_delivery=status.get("LatestDeliveryTime"),key=latest["Key"],version=head["VersionId"],retain_until=head.get("ObjectLockRetainUntilDate"),checked_utc=now.isoformat())
with tempfile.TemporaryDirectory() as folder:
    copy = Path(folder)/"restored.json.gz"
    a("s3api","get-object",*bucket,"--key",latest["Key"],"--version-id",head["VersionId"],str(copy))
    with gzip.open(copy,"rt",encoding="utf-8") as stream:
        records=json.load(stream).get("Records",[])
    require(records and any("eventID" in row for row in records),"Retrieved version contains no readable CloudTrail records")
    with copy.open("rb") as binary:
        proof["restored_gzip_sha256"]=hashlib.file_digest(binary,"sha256").hexdigest()
    proof["record_count"]=len(records)
out=Path(args.output);out.parent.mkdir(exist_ok=True,parents=True);out.write_text(json.dumps(proof,indent=2)+"\n")
print("PASS archived member log. Validate the digest chain independently as described in the runbook.")
