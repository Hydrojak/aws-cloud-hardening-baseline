"""Compare stored fixtures against the regional EventBridge TestEventPattern API."""
import argparse
import json
import subprocess
from pathlib import Path

root=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser(description=__doc__)
p.add_argument("--profile",required=True)
p.add_argument("--region",default="eu-west-1")
args=p.parse_args()
for case in json.loads((root/"tests/fixtures/events.json").read_text()):
    rule=(root/"catalog"/(case["rule"]+".json")).read_text()
    result=subprocess.check_output(["aws","--profile",args.profile,"--region",args.region,"--output","json",
                                  "events","test-event-pattern","--event-pattern",rule,"--event",json.dumps(case["event"])])
    if json.loads(result)["Result"] != case["matches"]: raise SystemExit("FAIL "+case["id"])
    print("PASS",case["id"])
