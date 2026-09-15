locals {
  global_runner_arn = "arn:aws:iam::${var.account_ids["global"]}:role/tf-${local.scope_names["global"]}-runner"
}

resource "aws_iam_role" "global_control_core_dev" {
  provider = aws.core_dev
  name     = "tf-global-control-plane"

  depends_on = [aws_iam_role.terraform_runner_global]

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = local.global_runner_arn }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "global_control_core_dev" {
  provider = aws.core_dev
  for_each = var.global_control_managed_policy_arns

  role       = aws_iam_role.global_control_core_dev.name
  policy_arn = each.value
}

resource "aws_iam_role" "global_control_core_prod" {
  provider = aws.core_prod
  name     = "tf-global-control-plane"

  depends_on = [aws_iam_role.terraform_runner_global]

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = local.global_runner_arn }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "global_control_core_prod" {
  provider = aws.core_prod
  for_each = var.global_control_managed_policy_arns

  role       = aws_iam_role.global_control_core_prod.name
  policy_arn = each.value
}

resource "aws_iam_role" "global_control_shared_network_dev" {
  provider = aws.shared_network_dev
  name     = "tf-global-control-plane"

  depends_on = [aws_iam_role.terraform_runner_global]

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = local.global_runner_arn }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "global_control_shared_network_dev" {
  provider = aws.shared_network_dev
  for_each = var.global_control_managed_policy_arns

  role       = aws_iam_role.global_control_shared_network_dev.name
  policy_arn = each.value
}

resource "aws_iam_role" "global_control_shared_network_prod" {
  provider = aws.shared_network_prod
  name     = "tf-global-control-plane"

  depends_on = [aws_iam_role.terraform_runner_global]

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = local.global_runner_arn }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "global_control_shared_network_prod" {
  provider = aws.shared_network_prod
  for_each = var.global_control_managed_policy_arns

  role       = aws_iam_role.global_control_shared_network_prod.name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "global_runner_assume_control_roles" {
  provider = aws.global
  name     = "assume-global-control-plane-roles"
  role     = aws_iam_role.terraform_runner_global.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Resource = [
        aws_iam_role.global_control_core_dev.arn,
        aws_iam_role.global_control_core_prod.arn,
        aws_iam_role.global_control_shared_network_dev.arn,
        aws_iam_role.global_control_shared_network_prod.arn,
      ]
    }]
  })
}
