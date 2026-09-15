#!/usr/bin/env bash
set -euo pipefail
cp demo/fixtures/secret_leak.py.example app/demo_secret_leak.py
echo "Enabled secret leak demo. Commit and push; Gitleaks should fail the SecurityScan stage."
