# DevSecOps Demo Scenarios

These scenarios are intentionally unsafe and are provided only to prove that the pipeline blocks bad changes before Terraform Apply.

## 1. Successful deployment

Push the baseline repository. Expected result:

`Source -> ValidateTest -> SecurityScan -> TerraformPlan -> ManualApproval -> TerraformApply -> PostDeployVerification -> SUCCEEDED`

Approve the ManualApproval stage only after reviewing `PlanOutput/plan.txt`.

## 2. Public SSH blocked by Checkov

```bash
./demo/scripts/enable-public-ssh.sh
git add workload/demo_public_ssh.tf
git commit -m "demo: intentionally expose ssh"
git push
```

Expected result: `SecurityScan` fails before Terraform Plan/Apply. The intentionally unsafe rule opens TCP/22 to `0.0.0.0/0`.

Reset:

```bash
./demo/scripts/reset-demo.sh
git add -A && git commit -m "demo: remove public ssh" && git push
```

## 3. Secret leak blocked by Gitleaks

```bash
./demo/scripts/enable-secret-leak.sh
git add app/demo_secret_leak.py
git commit -m "demo: intentionally leak fake credential"
git push
```

Expected result: `SecurityScan` fails in Gitleaks.

The fixture path is allowlisted so the clean baseline repository can contain the inert workshop example. Once copied into `app/`, it is no longer allowlisted.

## 4. Vulnerable dependency blocked by Trivy

```bash
./demo/scripts/enable-vulnerable-dependency.sh
git add app/requirements.txt
git commit -m "demo: intentionally add vulnerable dependency"
git push
```

Expected result: Trivy fails the security stage if the selected package version has a HIGH or CRITICAL advisory in the current vulnerability database.

If the advisory database changes and this fixture no longer triggers, replace the package version with a currently known vulnerable version for the live workshop. The demo mechanism is unchanged.

## 5. Manual Approval rejection

1. Push a safe change.
2. Wait until `ManualApproval`.
3. Download/review `PlanOutput/plan.txt`.
4. Choose **Reject** in CodePipeline.
5. Confirm that `TerraformApply` and `PostDeployVerification` never run.

## Safety rule

Never use real credentials in any demo. All secret examples must be fake and disposable.
