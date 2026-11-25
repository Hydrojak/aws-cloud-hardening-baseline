"""Exercise the live verifier's pass/fail criteria without AWS calls."""
import contextlib
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"scripts"))
import verify_delivery as probe


class ProbeEvidence(unittest.TestCase):
    def execute(self, scenario):
        topic="arn:aws:sns:eu-west-1:333333333333:baseline-security-alerts"
        sent=[]
        def api(profile, region, service, operation, *args):
            if service=="sts":return {"Account":"444444444444" if profile=="source" else "333333333333"}
            if operation=="list-subscriptions-by-topic":
                return {"Subscriptions":[{"Protocol":"email","SubscriptionArn":"PendingConfirmation" if scenario=="unconfirmed" else topic+":id"}]}
            if operation=="describe-alarms":
                return {"MetricAlarms":[{"AlarmActions":[topic],"ActionsEnabled":True,"StateValue":"OK"}]}
            if operation=="put-events":
                event=json.loads(args[-1])[0]
                sent.append({"eventId":region,"timestamp":2,
                             "message":json.dumps({"account":"444444444444","region":region,"detail":json.loads(event["Detail"])})})
                return {"FailedEntryCount":0,"Entries":[{"EventId":region}]}
            if operation=="filter-log-events":return {"events":sent[:1] if scenario=="lost" else sent}
            if operation=="describe-alarm-history":
                return {"AlarmHistoryItems":[{"HistoryData":json.dumps({"actionState":"Succeeded","notificationResource":topic}),"Timestamp":"2026-11-25T12:00:00Z"}]}
            raise AssertionError(operation)
        def poll_once(read, deadline, label):
            result=read()
            if not result:raise TimeoutError(label)
            return result
        with tempfile.TemporaryDirectory() as tmp:
            dest=Path(tmp)/"evidence.json"
            args=["probe","--source-profile","source","--security-profile","sec","--source-account","444444444444",
                  "--security-account","333333333333","--sns-topic",topic,"--output",str(dest)]
            error=None
            with patch.object(sys,"argv",args),patch.object(probe,"aws",api),patch.object(probe,"poll",poll_once),contextlib.redirect_stdout(io.StringIO()):
                try:probe.main()
                except (TimeoutError, RuntimeError) as exc:error=exc
            return error,json.loads(dest.read_text())
    def test_two_regions_required_for_success(self):
        error,proof=self.execute("ok")
        self.assertIsNone(error)
        self.assertEqual(set(proof["deliveries"]),{"eu-west-1","us-east-1"})
        self.assertEqual(proof["result"],"passed to SNS")
        self.assertIn("pending",proof["mailbox_receipt"])
    def test_missing_region_fails(self):
        error,proof=self.execute("lost")
        self.assertIsInstance(error,TimeoutError)
        self.assertEqual(proof["result"],"failed")
    def test_missing_recipient_fails(self):
        error,proof=self.execute("unconfirmed")
        self.assertIn("confirmed",str(error))
        self.assertEqual(proof["deliveries"],{})
