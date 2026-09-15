#!/usr/bin/env bash
set -euo pipefail
rm -f workload/demo_public_ssh.tf app/demo_secret_leak.py
git restore app/requirements.txt 2>/dev/null || true
echo "Demo changes reset. Commit the cleanup before rerunning the pipeline."
