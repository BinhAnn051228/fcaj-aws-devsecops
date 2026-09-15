# Workshop implementation map

| Workshop section | Source files |
| --- | --- |
| 5.1 Environment & architecture | `README.md`, `docs/architecture-v6.png` |
| 5.2 Terraform backend & state | `bootstrap/`, `platform/backend.tf`, `workload/backend.tf` |
| 5.3 IAM & secrets | `platform/iam.tf`, `iam-policy/`, `platform/secrets_notifications.tf` |
| 5.4 GitHub & CodePipeline source | `platform/pipeline.tf` |
| 5.5 Validate/Test/Shift-left security | `cicd/buildspec-validate-security.yml`, `.gitleaks.toml` |
| 5.6 Terraform Plan & Manual Approval | `cicd/buildspec-plan.yml`, `platform/pipeline.tf` |
| 5.7 Terraform Apply | `cicd/buildspec-apply.yml` |
| 5.8 Target environment | `workload/` |
| 5.9 Post-deploy verification | `cicd/buildspec-apply.yml` (`RUN_MODE=smoke`) |
| 5.10 Logging/Monitoring/Notification | `platform/codebuild.tf`, `platform/pipeline.tf`, `platform/cloudtrail.tf`, `platform/secrets_notifications.tf` |
| 5.11 Complete pipeline | `platform/pipeline.tf` |
| 5.12 DevSecOps demo scenarios | `demo/` |
| 5.13 Results & cleanup | `README.md` cleanup section |
