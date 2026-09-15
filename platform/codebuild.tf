resource "aws_cloudwatch_log_group" "validate_security" {
  name              = "/aws/codebuild/${local.name}-validate-security"
  retention_in_days = var.cloudwatch_log_retention_days
}

resource "aws_cloudwatch_log_group" "terraform_plan" {
  name              = "/aws/codebuild/${local.name}-terraform-plan"
  retention_in_days = var.cloudwatch_log_retention_days
}

resource "aws_cloudwatch_log_group" "terraform_apply" {
  name              = "/aws/codebuild/${local.name}-terraform-apply-smoke"
  retention_in_days = var.cloudwatch_log_retention_days
}

resource "aws_codebuild_project" "validate_security" {
  name          = "${local.name}-validate-security"
  description   = "Validate, unit test, secret scan, SAST, SCA and IaC scanning."
  service_role  = aws_iam_role.scan_build.arn
  build_timeout = 30

  artifacts {
    type = "CODEPIPELINE"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "cicd/buildspec-validate-security.yml"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = false

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "TF_VERSION"
      value = var.terraform_version
    }

    environment_variable {
      name  = "GITLEAKS_VERSION"
      value = var.gitleaks_version
    }

    environment_variable {
      name  = "TRIVY_VERSION"
      value = var.trivy_version
    }

    environment_variable {
      name  = "WORKLOAD_DIR"
      value = "workload"
    }

    environment_variable {
      name  = "RUN_MODE"
      value = "validate"
    }

    environment_variable {
      name  = "DEMO_TOKEN"
      value = aws_ssm_parameter.demo_token.name
      type  = "PARAMETER_STORE"
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.validate_security.name
      stream_name = "build"
    }
  }
}

resource "aws_codebuild_project" "terraform_plan" {
  name          = "${local.name}-terraform-plan"
  description   = "Create an immutable Terraform plan artifact for manual review."
  service_role  = aws_iam_role.terraform_plan.arn
  build_timeout = 30

  artifacts {
    type = "CODEPIPELINE"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "cicd/buildspec-plan.yml"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = false

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "TF_VERSION"
      value = var.terraform_version
    }

    environment_variable {
      name  = "TF_STATE_BUCKET"
      value = var.terraform_state_bucket
    }

    environment_variable {
      name  = "TF_STATE_KEY"
      value = local.workload_key
    }

    environment_variable {
      name  = "WORKLOAD_DIR"
      value = "workload"
    }

    environment_variable {
      name  = "TF_IN_AUTOMATION"
      value = "true"
    }

    environment_variable {
      name  = "TF_VAR_project_name"
      value = var.project_name
    }

    environment_variable {
      name  = "TF_VAR_environment"
      value = var.environment
    }

    environment_variable {
      name  = "TF_VAR_aws_region"
      value = var.aws_region
    }

    environment_variable {
      name  = "TF_VAR_instance_type"
      value = var.instance_type
    }
    environment_variable {
      name  = "TF_VAR_instance_profile_name"
      value = aws_iam_instance_profile.ec2_demo.name
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.terraform_plan.name
      stream_name = "build"
    }
  }
}

resource "aws_codebuild_project" "terraform_apply_smoke" {
  name          = "${local.name}-terraform-apply-smoke"
  description   = "Apply the approved Terraform plan and perform post-deploy smoke testing."
  service_role  = aws_iam_role.terraform_deploy.arn
  build_timeout = 45

  artifacts {
    type = "CODEPIPELINE"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "cicd/buildspec-apply.yml"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = false

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "TF_VERSION"
      value = var.terraform_version
    }

    environment_variable {
      name  = "TF_STATE_BUCKET"
      value = var.terraform_state_bucket
    }

    environment_variable {
      name  = "TF_STATE_KEY"
      value = local.workload_key
    }

    environment_variable {
      name  = "WORKLOAD_DIR"
      value = "workload"
    }

    environment_variable {
      name  = "TF_IN_AUTOMATION"
      value = "true"
    }

    environment_variable {
      name  = "RUN_MODE"
      value = "apply"
    }

    environment_variable {
      name  = "TF_VAR_project_name"
      value = var.project_name
    }

    environment_variable {
      name  = "TF_VAR_environment"
      value = var.environment
    }

    environment_variable {
      name  = "TF_VAR_aws_region"
      value = var.aws_region
    }

    environment_variable {
      name  = "TF_VAR_instance_type"
      value = var.instance_type
    }
    environment_variable {
      name  = "TF_VAR_instance_profile_name"
      value = aws_iam_instance_profile.ec2_demo.name
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.terraform_apply.name
      stream_name = "build"
    }
  }
}
