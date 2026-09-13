variable "project_name" {
  type        = string
  description = "Project name prefix."
  default     = "fcaj-devsecops"
}

variable "environment" {
  type        = string
  description = "Environment name used in tags and SSM paths."
  default     = "dev"
}

variable "aws_region" {
  type        = string
  description = "AWS Region."
  default     = "ap-southeast-1"
}

variable "github_owner" {
  type        = string
  description = "GitHub organization or username."
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name."
}

variable "github_branch" {
  type        = string
  description = "GitHub branch watched by CodePipeline."
  default     = "main"
}

variable "terraform_state_bucket" {
  type        = string
  description = "S3 bucket created by bootstrap for Terraform state."
}

variable "pipeline_artifact_bucket" {
  type        = string
  description = "S3 bucket created by bootstrap for CodePipeline artifacts."
}

variable "terraform_version" {
  type        = string
  description = "Terraform CLI version installed in CodeBuild."
  default     = "1.16.2"
}

variable "gitleaks_version" {
  type        = string
  description = "Gitleaks version installed in the security build."
  default     = "8.30.1"
}

variable "trivy_version" {
  type        = string
  description = "Trivy version installed in the security build."
  default     = "0.74.0"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type deployed by the workload pipeline."
  default     = "t3.micro"
}

variable "notification_email" {
  type        = string
  description = "Optional email for SNS and AWS Budgets notifications. Leave empty to disable email subscription."
  default     = ""
}

variable "budget_limit_usd" {
  type        = number
  description = "Monthly cost budget for the workshop."
  default     = 5
}

variable "cloudwatch_log_retention_days" {
  type        = number
  description = "Retention for CodeBuild log groups."
  default     = 14
}

variable "enable_cloudtrail" {
  type        = bool
  description = "Create a dedicated CloudTrail trail and log bucket."
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Additional tags."
  default     = {}
}
