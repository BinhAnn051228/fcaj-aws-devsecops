#!/usr/bin/env bash
set -euo pipefail

: "${TF_STATE_BUCKET:?Set TF_STATE_BUCKET to bootstrap output}"
: "${AWS_REGION:=ap-southeast-1}"

terraform -chdir=platform init -reconfigure \
  -backend-config="bucket=${TF_STATE_BUCKET}" \
  -backend-config="key=platform/terraform.tfstate" \
  -backend-config="region=${AWS_REGION}" \
  -backend-config="encrypt=true" \
  -backend-config="use_lockfile=true"
