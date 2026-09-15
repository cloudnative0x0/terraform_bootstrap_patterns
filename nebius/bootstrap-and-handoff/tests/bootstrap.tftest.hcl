mock_provider "nebius" {}

variables {
  tenant_id = "tenant-example"
  project_ids = {
    global             = "project-global", core_dev = "project-core-dev", core_prod = "project-core-prod",
    shared_network_dev = "project-network-dev", shared_network_prod = "project-network-prod"
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
  runner_roles = {
    global = [], core_dev = [], core_prod = [], shared_network_dev = [], shared_network_prod = []
  }
  global_runner_roles = []
}

run "bootstrap_plan" {
  command = plan

  assert {
    condition     = length(nebius_storage_v1_bucket.terraform_state) == 5
    error_message = "Bootstrap must create one state bucket per project."
  }
  assert {
    condition     = length(nebius_iam_v1_federated_credentials.terraform_runner) == 5
    error_message = "Every runner must have an immutable GitHub OIDC binding."
  }
  assert {
    condition     = nebius_storage_v1_bucket.terraform_state["core_prod"].versioning_policy == "ENABLED"
    error_message = "Production state versioning must be enabled."
  }
  assert {
    condition     = toset(nebius_storage_v1_bucket.terraform_state["global"].bucket_policy.rules[0].roles) == toset(["storage.editor"])
    error_message = "The state identity group must have object-only editor access."
  }
  assert {
    condition     = nebius_iam_v1_federated_credentials.terraform_runner["core_prod"].federated_subject_id == local.external_subject_ids["core_prod"]
    error_message = "The production runner must use the immutable GitHub subject."
  }
}
