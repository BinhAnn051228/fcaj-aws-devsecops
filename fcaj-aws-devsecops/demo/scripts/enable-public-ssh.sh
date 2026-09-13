#!/usr/bin/env bash
set -euo pipefail
cp demo/fixtures/public_ssh.tf.example workload/demo_public_ssh.tf
echo "Enabled public SSH demo. Commit and push; Checkov should fail the SecurityScan stage."
