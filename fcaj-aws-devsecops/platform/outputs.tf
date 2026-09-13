output "pipeline_name" {
  value = aws_codepipeline.main.name
}

output "github_connection_arn" {
  value = aws_codeconnections_connection.github.arn
}

output "github_connection_status" {
  value = aws_codeconnections_connection.github.connection_status
}

output "approval_topic_arn" {
  value = aws_sns_topic.pipeline.arn
}

output "demo_parameter_name" {
  value = aws_ssm_parameter.demo_token.name
}

output "codebuild_projects" {
  value = {
    validate_security = aws_codebuild_project.validate_security.name
    terraform_plan    = aws_codebuild_project.terraform_plan.name
    apply_smoke       = aws_codebuild_project.terraform_apply_smoke.name
  }
}

output "cloudtrail_name" {
  value = var.enable_cloudtrail ? aws_cloudtrail.main[0].name : null
}
