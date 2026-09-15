mock_provider "aws" { alias = "global" }
mock_provider "aws" { alias = "core_dev" }
mock_provider "aws" { alias = "core_prod" }
mock_provider "aws" { alias = "shared_network_dev" }
mock_provider "aws" { alias = "shared_network_prod" }

variables {
  account_ids = {
    global             = "111111111111", core_dev = "222222222222", core_prod = "333333333333",
    shared_network_dev = "444444444444", shared_network_prod = "555555555555"
  }
  bootstrap_profiles = {
    global             = "global", core_dev = "dev", core_prod = "prod",
    shared_network_dev = "network-dev", shared_network_prod = "network-prod"
  }
  name_prefix = "example"
  github = {
    organization = "example-org", organization_id = "123456789"
    repositories = {
      global              = { name = "tf-global-control-plane", repository_id = "1", environment = "global-platform" }
      core_dev            = { name = "tf-infrastructure", repository_id = "2", environment = "core-dev" }
      core_prod           = { name = "tf-infrastructure", repository_id = "2", environment = "core-prod" }
      shared_network_dev  = { name = "tf-shared-network", repository_id = "3", environment = "shared-network-dev" }
      shared_network_prod = { name = "tf-shared-network", repository_id = "3", environment = "shared-network-prod" }
    }
  }
  runner_managed_policy_arns = {
    global = [], core_dev = [], core_prod = [], shared_network_dev = [], shared_network_prod = []
  }
  global_control_managed_policy_arns = []
}

run "bootstrap_plan" {
  command = plan

  assert {
    condition     = length(local.external_subject_ids) == 5
    error_message = "Exactly five immutable GitHub OIDC subjects must be defined."
  }
  assert {
    condition     = aws_s3_bucket_versioning.state_core_prod.versioning_configuration[0].status == "Enabled"
    error_message = "Production state bucket versioning must be enabled."
  }
  assert {
    condition     = aws_s3_bucket_public_access_block.state_global.restrict_public_buckets
    error_message = "State buckets must block public access."
  }
  assert {
    condition     = local.external_subject_ids["core_prod"] == "repo:example-org@123456789/tf-infrastructure@2:environment:core-prod"
    error_message = "The production runner trust policy input must use the immutable GitHub subject."
  }
  assert {
    condition = alltrue([
      aws_iam_role.global_control_core_dev.name == "tf-global-control-plane",
      aws_iam_role.global_control_core_prod.name == "tf-global-control-plane",
      aws_iam_role.global_control_shared_network_dev.name == "tf-global-control-plane",
      aws_iam_role.global_control_shared_network_prod.name == "tf-global-control-plane",
    ])
    error_message = "Every non-global account must expose a role for the global control-plane runner."
  }
}
