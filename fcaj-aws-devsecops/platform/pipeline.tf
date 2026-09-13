resource "aws_codeconnections_connection" "github" {
  name          = "${local.name}-github"
  provider_type = "GitHub"
}

resource "aws_iam_role_policy" "codepipeline" {
  name = "${local.name}-codepipeline-policy"
  role = aws_iam_role.codepipeline.id

  policy = templatefile("${path.module}/../iam-policy/codepipeline-policy.json.tftpl", {
    artifact_bucket_arn       = "arn:${data.aws_partition.current.partition}:s3:::${var.pipeline_artifact_bucket}"
    connection_arn            = aws_codeconnections_connection.github.arn
    codebuild_project_arns_json = jsonencode([
      aws_codebuild_project.validate_security.arn,
      aws_codebuild_project.terraform_plan.arn,
      aws_codebuild_project.terraform_apply_smoke.arn
    ])
    sns_topic_arn = aws_sns_topic.pipeline.arn
  })
}

resource "aws_codepipeline" "main" {
  name           = "${local.name}-pipeline"
  role_arn       = aws_iam_role.codepipeline.arn
  pipeline_type  = "V1"
  execution_mode = "SUPERSEDED"

  artifact_store {
    location = var.pipeline_artifact_bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "GitHubSource"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["SourceOutput"]

      configuration = {
        ConnectionArn    = aws_codeconnections_connection.github.arn
        FullRepositoryId = local.repo_full_name
        BranchName       = var.github_branch
        DetectChanges    = "true"
      }
    }
  }

  stage {
    name = "ValidateTest"

    action {
      name            = "ValidateAndUnitTest"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["SourceOutput"]

      configuration = {
        ProjectName = aws_codebuild_project.validate_security.name
        EnvironmentVariables = jsonencode([
          { name = "RUN_MODE", value = "validate", type = "PLAINTEXT" }
        ])
      }
    }
  }

  stage {
    name = "SecurityScan"

    action {
      name            = "ShiftLeftSecurity"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["SourceOutput"]

      configuration = {
        ProjectName = aws_codebuild_project.validate_security.name
        EnvironmentVariables = jsonencode([
          { name = "RUN_MODE", value = "security", type = "PLAINTEXT" }
        ])
      }
    }
  }

  stage {
    name = "TerraformPlan"

    action {
      name             = "CreatePlan"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["SourceOutput"]
      output_artifacts = ["PlanOutput"]

      configuration = {
        ProjectName = aws_codebuild_project.terraform_plan.name
      }
    }
  }

  stage {
    name = "ManualApproval"

    action {
      name     = "ReviewTerraformPlan"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"

      configuration = {
        NotificationArn = aws_sns_topic.pipeline.arn
        CustomData      = "Review PlanOutput/plan.txt. Approve only if the planned infrastructure change is expected and safe."
      }
    }
  }

  stage {
    name = "TerraformApply"

    action {
      name            = "ApplyApprovedPlan"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["SourceOutput", "PlanOutput"]

      configuration = {
        ProjectName  = aws_codebuild_project.terraform_apply_smoke.name
        PrimarySource = "SourceOutput"
        EnvironmentVariables = jsonencode([
          { name = "RUN_MODE", value = "apply", type = "PLAINTEXT" }
        ])
      }
    }
  }

  stage {
    name = "PostDeployVerification"

    action {
      name            = "SmokeTest"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["SourceOutput"]

      configuration = {
        ProjectName = aws_codebuild_project.terraform_apply_smoke.name
        EnvironmentVariables = jsonencode([
          { name = "RUN_MODE", value = "smoke", type = "PLAINTEXT" }
        ])
      }
    }
  }

  depends_on = [aws_iam_role_policy.codepipeline]
}

resource "aws_cloudwatch_event_rule" "pipeline_state" {
  name        = "${local.name}-pipeline-state"
  description = "Send pipeline success/failure state changes to SNS."

  event_pattern = jsonencode({
    source      = ["aws.codepipeline"]
    "detail-type" = ["CodePipeline Pipeline Execution State Change"]
    detail = {
      pipeline = [aws_codepipeline.main.name]
      state    = ["FAILED", "SUCCEEDED", "CANCELED"]
    }
  })
}

resource "aws_cloudwatch_event_target" "pipeline_state_sns" {
  rule      = aws_cloudwatch_event_rule.pipeline_state.name
  target_id = "PipelineSns"
  arn       = aws_sns_topic.pipeline.arn

  depends_on = [aws_sns_topic_policy.pipeline]
}
