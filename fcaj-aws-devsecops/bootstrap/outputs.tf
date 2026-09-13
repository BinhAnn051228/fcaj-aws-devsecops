output "terraform_state_bucket" {
  description = "S3 bucket used by platform and workload Terraform backends."
  value       = aws_s3_bucket.terraform_state.bucket
}

output "pipeline_artifact_bucket" {
  description = "S3 bucket used by AWS CodePipeline artifacts."
  value       = aws_s3_bucket.pipeline_artifacts.bucket
}

output "aws_region" {
  value = var.aws_region
}
