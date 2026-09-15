#!/usr/bin/env python3
"""Offline structural checks for the workshop source tree.

This does not replace `terraform validate`, which requires the Terraform CLI and
provider downloads. It validates YAML, IAM JSON templates, file counts, and
basic Terraform brace balance so packaging mistakes are caught early.
"""
from pathlib import Path
import json
import re
import sys
import yaml

ROOT = Path(__file__).resolve().parents[1]

buildspecs = sorted((ROOT / "cicd").glob("buildspec-*.yml"))
if len(buildspecs) != 3:
    raise SystemExit(f"Expected exactly 3 buildspec files, found {len(buildspecs)}")
for path in buildspecs:
    yaml.safe_load(path.read_text())
    print(f"YAML OK: {path.relative_to(ROOT)}")

values = {
    "artifact_bucket_arn": "arn:aws:s3:::example-artifacts",
    "connection_arn": "arn:aws:codeconnections:ap-southeast-1:123456789012:connection/example",
    "codebuild_project_arns_json": '["arn:aws:codebuild:ap-southeast-1:123456789012:project/example"]',
    "sns_topic_arn": "arn:aws:sns:ap-southeast-1:123456789012:example",
    "log_group_arn": "arn:aws:logs:ap-southeast-1:123456789012:log-group:/aws/codebuild/example",
    "ssm_parameter_arn": "arn:aws:ssm:ap-southeast-1:123456789012:parameter/example",
    "state_bucket_arn": "arn:aws:s3:::example-state",
    "state_key": "workload/terraform.tfstate",
}
for path in sorted((ROOT / "iam-policy").glob("*.tftpl")):
    rendered = path.read_text()
    for key, value in values.items():
        rendered = rendered.replace("${" + key + "}", value)
    leftovers = re.findall(r"\$\{[^}]+\}", rendered)
    if leftovers:
        raise SystemExit(f"Unresolved template variables in {path}: {leftovers}")
    json.loads(rendered)
    print(f"IAM JSON template OK: {path.relative_to(ROOT)}")

for path in sorted(ROOT.rglob("*.tf")):
    text = path.read_text()
    if text.count("{") != text.count("}"):
        raise SystemExit(f"Terraform brace mismatch: {path.relative_to(ROOT)}")
print("Basic Terraform brace balance OK")

required = [
    ROOT / "platform" / "pipeline.tf",
    ROOT / "workload" / "main.tf",
    ROOT / "demo" / "README.md",
    ROOT / "docs" / "architecture-v6.png",
]
for path in required:
    if not path.exists():
        raise SystemExit(f"Missing required file: {path}")

print("Source tree structural validation PASSED")
