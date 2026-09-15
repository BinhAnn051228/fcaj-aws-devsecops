#!/usr/bin/env bash
set -euo pipefail
cp demo/fixtures/requirements-vulnerable.txt app/requirements.txt
echo "Enabled vulnerable dependency demo. Commit and push; Trivy should fail the SecurityScan stage."
