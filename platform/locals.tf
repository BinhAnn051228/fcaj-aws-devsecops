provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge({
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Layer       = "platform"
    }, var.tags)
  }
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  name             = "${replace(lower(var.project_name), "_", "-")}-${var.environment}"
  repo_full_name   = "${var.github_owner}/${var.github_repo}"
  workload_key     = "workload/terraform.tfstate"
  demo_token_path  = "/${replace(lower(var.project_name), "_", "-")}/${var.environment}/demo_token"
  trail_name       = "${local.name}-trail"
  trail_bucket     = "${local.name}-${data.aws_caller_identity.current.account_id}-${var.aws_region}-cloudtrail"
  trail_arn        = "arn:${data.aws_partition.current.partition}:cloudtrail:${var.aws_region}:${data.aws_caller_identity.current.account_id}:trail/${local.trail_name}"
}
