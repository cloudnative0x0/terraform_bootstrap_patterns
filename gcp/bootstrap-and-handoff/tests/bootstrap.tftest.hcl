mock_provider "google" {}

variables {
  project_ids = {
    global             = "example-global", core_dev = "example-core-dev", core_prod = "example-core-prod",
    shared_network_dev = "example-network-dev", shared_network_prod = "example-network-prod"
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
  runner_project_roles = {
    global = [], core_dev = [], core_prod = [], shared_network_dev = [], shared_network_prod = []
  }
  global_runner_project_roles = []
}

run "bootstrap_plan" {
  command = plan

  assert {
    condition     = length(google_storage_bucket.terraform_state) == 5
    error_message = "Bootstrap must create one state bucket per project."
  }
  assert {
    condition     = length(google_iam_workload_identity_pool.github) == 5
    error_message = "Each scope must have an isolated workload identity pool."
  }
  assert {
    condition     = google_storage_bucket.terraform_state["core_prod"].versioning[0].enabled
    error_message = "Production state versioning must be enabled."
  }
  assert {
    condition     = google_storage_bucket.terraform_state["global"].public_access_prevention == "enforced"
    error_message = "Public access prevention must be enforced."
  }
  assert {
    condition     = google_iam_workload_identity_pool_provider.github["core_prod"].attribute_condition == "assertion.sub == '${local.external_subject_ids["core_prod"]}'"
    error_message = "The production provider must require the immutable GitHub subject."
  }
}
