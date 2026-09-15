output "bootstrap" {
  description = "AWS state backends and GitHub OIDC runner roles"
  value = {
    global = {
      account_id      = var.account_ids["global"]
      bucket          = aws_s3_bucket.state_global.bucket
      runner_role_arn = aws_iam_role.terraform_runner_global.arn
      state_role_arn  = aws_iam_role.terraform_state_global.arn
    }
    core_dev = {
      account_id       = var.account_ids["core_dev"]
      bucket           = aws_s3_bucket.state_core_dev.bucket
      runner_role_arn  = aws_iam_role.terraform_runner_core_dev.arn
      state_role_arn   = aws_iam_role.terraform_state_core_dev.arn
      control_role_arn = aws_iam_role.global_control_core_dev.arn
    }
    core_prod = {
      account_id       = var.account_ids["core_prod"]
      bucket           = aws_s3_bucket.state_core_prod.bucket
      runner_role_arn  = aws_iam_role.terraform_runner_core_prod.arn
      state_role_arn   = aws_iam_role.terraform_state_core_prod.arn
      control_role_arn = aws_iam_role.global_control_core_prod.arn
    }
    shared_network_dev = {
      account_id       = var.account_ids["shared_network_dev"]
      bucket           = aws_s3_bucket.state_shared_network_dev.bucket
      runner_role_arn  = aws_iam_role.terraform_runner_shared_network_dev.arn
      state_role_arn   = aws_iam_role.terraform_state_shared_network_dev.arn
      control_role_arn = aws_iam_role.global_control_shared_network_dev.arn
    }
    shared_network_prod = {
      account_id       = var.account_ids["shared_network_prod"]
      bucket           = aws_s3_bucket.state_shared_network_prod.bucket
      runner_role_arn  = aws_iam_role.terraform_runner_shared_network_prod.arn
      state_role_arn   = aws_iam_role.terraform_state_shared_network_prod.arn
      control_role_arn = aws_iam_role.global_control_shared_network_prod.arn
    }
  }
}
