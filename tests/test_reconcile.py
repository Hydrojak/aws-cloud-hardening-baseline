import copy
import importlib.util
import json
from pathlib import Path
import unittest
from unittest.mock import Mock

root = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("trail_health", root / "terraform/modules/remediation-cloudtrail/lambda/index.py")
health = importlib.util.module_from_spec(spec)
spec.loader.exec_module(health)

class TrailHealth(unittest.TestCase):
    def setUp(self):
        self.arn = "arn:aws:cloudtrail:eu-west-1:111111111111:trail/baseline"
        self.role = "arn:aws:iam::111111111111:role/baseline-check"
        self.flags = {"S3BucketName":"archive", "IsMultiRegionTrail":True, "IncludeGlobalServiceEvents":True, "EnableLogFileValidation":True}
        self.selectors = [{"ReadWriteType":"All","IncludeManagementEvents":True}]
        self.cfg = dict(TRAIL_ARN=self.arn, HOME_REGION="eu-west-1", ROLE_ARN=self.role, ORG_TRAIL="true",
                        EXPECTED_SELECTORS=json.dumps(self.selectors), EXPECTED_FLAGS=json.dumps(self.flags), REPAIR="true")
        self.api = Mock()
        self.api.get_trail.return_value = {"Trail":dict(self.flags, IsOrganizationTrail=True)}
        response = self.api.get_trail.return_value["Trail"]
        response["LogFileValidationEnabled"] = response.pop("EnableLogFileValidation")
        self.api.get_trail_status.return_value = {"IsLogging":True}
        self.api.get_event_selectors.return_value = {"EventSelectors":copy.deepcopy(self.selectors)}
        self.event = {"source":"aws.cloudtrail", "account":"111111111111","region":"eu-west-1","detail":{
            "eventSource":"cloudtrail.amazonaws.com","eventName":"UpdateTrail","requestParameters":{"name":self.arn}}}
        self.timer = {"source":"aws.events", "detail-type":"Scheduled Event"}

    def run_check(self):
        return health.reconcile(self.api, self.event, self.cfg)

    def no_writes(self):
        for name in ("start_logging","update_trail","put_event_selectors"):
            getattr(self.api,name).assert_not_called()

    def test_self_event(self):
        self.event["detail"]["userIdentity"]={"sessionContext":{"sessionIssuer":{"arn":self.role}}}
        self.assertEqual(self.run_check(),"ignored")
        self.assertEqual(self.api.mock_calls,[])

    def test_other_trail_account_region_or_denied_request(self):
        changes=[("region","us-east-1"),("account","999999999999"),("source","custom.source")]
        for k,val in changes:
            event=dict(self.event,**{k:val})
            self.assertEqual(health.reconcile(self.api,event,self.cfg),"ignored")
        self.event["detail"]["requestParameters"]={"trailName":"unrelated"}
        self.assertEqual(self.run_check(),"ignored")
        self.event["detail"].update(requestParameters={"name":self.arn},errorCode="AccessDenied")
        self.assertEqual(self.run_check(),"ignored")
        self.assertEqual(self.api.mock_calls,[])

    def test_healthy_no_writes(self):
        self.assertEqual(self.run_check(),"checked")
        self.no_writes()

    def test_only_drift_then_redelivery(self):
        self.api.get_trail.return_value["Trail"]["LogFileValidationEnabled"]=False
        self.run_check()
        self.api.update_trail.assert_called_once_with(Name=self.arn,EnableLogFileValidation=True)
        self.api.get_trail.return_value["Trail"]["LogFileValidationEnabled"]=True
        self.run_check()
        self.assertEqual(self.api.update_trail.call_count,1)

    def test_restart_once(self):
        self.api.get_trail_status.return_value["IsLogging"]=False
        self.run_check()
        self.api.start_logging.assert_called_once_with(Name=self.arn)
        self.api.update_trail.assert_not_called()

    def test_monitor_only_no_writes(self):
        self.cfg["REPAIR"]="false"
        self.api.get_trail_status.return_value["IsLogging"]=False
        with self.assertRaisesRegex(RuntimeError,"monitor-only"):
            health.reconcile(self.api,self.timer,self.cfg)
        self.no_writes()

    def test_protect_advanced_selectors(self):
        self.api.get_event_selectors.return_value={"AdvancedEventSelectors":[{"Name":"protected"}]}
        with self.assertRaisesRegex(RuntimeError,"requires review"):self.run_check()
        self.no_writes()

    def test_organization_drift_needs_operator(self):
        self.api.get_trail.return_value["Trail"]["IsOrganizationTrail"]=False
        with self.assertRaisesRegex(RuntimeError,"review"):self.run_check()
        self.no_writes()

    def test_failed_api_call_propagates(self):
        self.api.get_trail.side_effect=PermissionError("denied")
        with self.assertRaises(PermissionError):self.run_check()
        self.no_writes()

    def test_deleted_trail_or_insights_escalates(self):
        for name in ("DeleteTrail","PutInsightSelectors"):
            self.event["detail"]["eventName"]=name
            with self.assertRaisesRegex(RuntimeError,"Operator review"):self.run_check()
        self.no_writes()

    def test_wrong_basic_selectors_replaced(self):
        self.api.get_event_selectors.return_value={"EventSelectors":[dict(self.selectors[0],ReadWriteType="WriteOnly")]}
        self.run_check()
        self.api.put_event_selectors.assert_called_once_with(TrailName=self.arn,EventSelectors=self.selectors)

    def test_aws_selector_defaults_do_not_trigger_write(self):
        self.api.get_event_selectors.return_value={"EventSelectors":[dict(self.selectors[0],DataResources=[],ExcludeManagementEventSources=[])]}
        self.run_check()
        self.no_writes()

    def test_delivery_failure_surfaces(self):
        self.api.get_trail_status.return_value["LatestDeliveryError"]="AccessDenied"
        with self.assertRaisesRegex(RuntimeError,"delivery error"):self.run_check()

    def test_scheduled_success_emits_heartbeat(self):
        with self.assertLogs(level="INFO") as logs:health.reconcile(self.api,self.timer,self.cfg)
        self.assertIn("scheduled_check_completed"," ".join(logs.output))

if __name__ == "__main__":
    unittest.main()
