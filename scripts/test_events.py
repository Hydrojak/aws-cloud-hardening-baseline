"""Run the catalog through AWS Event Ruler with pinned, checksum-verified test dependencies."""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import urllib.request

root = Path(__file__).resolve().parents[1]
cache = Path(os.getenv("RULER_CACHE", Path.home() / ".cache/aws-baseline/event-ruler"))
cache.mkdir(exist_ok=True, parents=True)
jars = []
for dep in json.loads((root / "tests/ruler/jars.json").read_text()):
    path = cache / dep["url"].split("/")[-1]
    if not path.exists():
        with urllib.request.urlopen(dep["url"], timeout=60) as response:
            blob = response.read()
        if hashlib.sha256(blob).hexdigest() != dep["sha256"]:
            raise SystemExit("Checksum mismatch: " + path.name)
        path.write_bytes(blob)
    if hashlib.sha256(path.read_bytes()).hexdigest() != dep["sha256"]:
        raise SystemExit("Checksum mismatch: " + path.name)
    jars.append(str(path.resolve()))
subprocess.run(["java", "-cp", os.pathsep.join(jars), "tests/ruler/Check.java"], cwd=root, check=True)
