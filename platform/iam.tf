data "aws_iam_policy_document" "codepipeline_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "codebuild_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codepipeline" {
  name               = "${local.name}-CodePipelineRole"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume.json
}

resource "aws_iam_role" "scan_build" {
  name               = "${local.name}-ScanBuildRole"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json
}

resource "aws_iam_role" "terraform_plan" {
  name               = "${local.name}-TerraformPlanRole"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json
}

resource "aws_iam_role" "terraform_deploy" {
  name               = "${local.name}-TerraformDeployRole"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json
}

resource "aws_iam_role_policy" "scan_build" {
  name = "${local.name}-scan-build-policy"
  role = aws_iam_role.scan_build.id

  policy = templatefile("${path.module}/../iam-policy/scan-build-policy.json.tftpl", {
    artifact_bucket_arn  = "arn:${data.aws_partition.current.partition}:s3:::${var.pipeline_artifact_bucket}"
    log_group_arn        = aws_cloudwatch_log_group.validate_security.arn
    ssm_parameter_arn    = aws_ssm_parameter.demo_token.arn
    instance_profile_arn = aws_iam_instance_profile.ec2_demo.arn
    ec2_role_arn         = aws_iam_role.ec2_demo.arn
  })
}

resource "aws_iam_role_policy" "terraform_plan" {
  name = "${local.name}-terraform-plan-policy"
  role = aws_iam_role.terraform_plan.id

  policy = templatefile("${path.module}/../iam-policy/terraform-plan-policy.json.tftpl", {
    artifact_bucket_arn  = "arn:${data.aws_partition.current.partition}:s3:::${var.pipeline_artifact_bucket}"
    state_bucket_arn     = "arn:${data.aws_partition.current.partition}:s3:::${var.terraform_state_bucket}"
    state_key            = local.workload_key
    log_group_arn        = aws_cloudwatch_log_group.terraform_plan.arn
    instance_profile_arn = aws_iam_instance_profile.ec2_demo.arn
  })
}

resource "aws_iam_role_policy" "terraform_deploy" {
  name = "${local.name}-terraform-deploy-policy"
  role = aws_iam_role.terraform_deploy.id

  policy = templatefile("${path.module}/../iam-policy/terraform-deploy-policy.json.tftpl", {
    artifact_bucket_arn = "arn:${data.aws_partition.current.partition}:s3:::${var.pipeline_artifact_bucket}"
    state_bucket_arn    = "arn:${data.aws_partition.current.partition}:s3:::${var.terraform_state_bucket}"
    state_key           = local.workload_key
    log_group_arn       = aws_cloudwatch_log_group.terraform_apply.arn
  })
}
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ec2_demo" {
  name               = "${local.name}-EC2DemoRole"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_role_policy_attachment" "ec2_demo_ssm" {
  role       = aws_iam_role.ec2_demo.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_instance_profile" "ec2_demo" {
  name = "${local.name}-EC2DemoProfile"
  role = aws_iam_role.ec2_demo.name
}

