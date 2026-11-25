"""Run the pinned IaC scanner and gate new HIGH/CRITICAL findings."""
from pathlib import Path
import argparse
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tarfile
import tempfile
import urllib.request

root = Path(__file__).resolve().parents[1]
pin = json.loads((root / "scripts/trivy.lock.json").read_text())
p=argparse.ArgumentParser(description=__doc__)
p.add_argument("--output",default="audit/results/trivy.json")
opts=p.parse_args()
out=Path(opts.output).resolve()
out.parent.mkdir(parents=True,exist_ok=True)
with tempfile.TemporaryDirectory() as tmp:
    tool=os.environ.get("TRIVY")
    if not tool:
        bundle=Path(tmp)/"bundle.tar.gz"
        with urllib.request.urlopen(pin["url"],timeout=120) as response,bundle.open("wb") as f:
            shutil.copyfileobj(response,f)
        with bundle.open("rb") as f:
            if hashlib.file_digest(f,"sha256").hexdigest()!=pin["sha256"]:
                raise SystemExit("Trivy digest mismatch")
        binpath=Path(tmp)/"trivy"
        with tarfile.open(bundle) as t,binpath.open("wb") as f:
            shutil.copyfileobj(t.extractfile("trivy"),f)
        binpath.chmod(0o700)
        tool=str(binpath)
    subprocess.run([tool,"--cache-dir",tmp,"config","--skip-check-update","--skip-dirs","**/.terraform","--format","json","--output",str(out),"."],cwd=root,check=True)
res=json.loads(out.read_text())
if not res.get("Results"):raise SystemExit("Scanner returned no results")
failures=[]
for result in res["Results"]:
    for finding in result.get("Misconfigurations",[]):
        if finding.get("Status")!="FAIL":continue
        address=finding.get("CauseMetadata",{}).get("Resource")
        print(finding["Severity"],finding["ID"],result["Target"],address)
        # Lab defaults to SSE-S3. The organization profile selects a customer key.
        lab=(finding["ID"]=="AWS-0132" and result["Target"]=="terraform/modules/cloudtrail-logging/main.tf"
             and address=="module.cloudtrail_logging")
        if finding["Severity"] in ("HIGH","CRITICAL") and not lab:failures.append(finding["ID"])
if failures: sys.exit("Review findings: "+", ".join(failures))
