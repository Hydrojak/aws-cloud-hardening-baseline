#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mode=${1:-ci}
case "$mode" in local|ci) ;; *) echo 'Usage: scripts/check.sh [local|ci]' >&2; exit 2 ;; esac
terraform fmt -check -recursive .
python3 -m unittest discover -s tests -v
python3 scripts/test_events.py
terraform -chdir=terraform/modules/bus-policy test -no-color
terraform -chdir=terraform/modules/archive-policy test -no-color
if [[ "$mode" == ci ]]; then
  for root in terraform stacks/{state,archive,management,security,member,identity}; do
    terraform -chdir="$root" init -backend=false -input=false -lockfile=readonly
    terraform -chdir="$root" validate -no-color
    terraform -chdir="$root" test -no-color
  done
  python3 scripts/scan.py
fi
