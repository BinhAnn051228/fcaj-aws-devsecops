SHELL := /bin/bash

.PHONY: test fmt security clean

test:
	python3 -m pip install -r app/requirements.txt pytest
	pytest -q app/tests

fmt:
	terraform fmt -recursive -check bootstrap platform workload

security:
	gitleaks detect --source . --config .gitleaks.toml --redact --no-banner
	bandit -r app -lll -iii
	trivy fs --scanners vuln --severity HIGH,CRITICAL --exit-code 1 --ignore-unfixed app/
	checkov -d workload --framework terraform --compact

clean:
	rm -rf app/__pycache__ app/tests/__pycache__ .pytest_cache
	rm -f workload/demo_public_ssh.tf
