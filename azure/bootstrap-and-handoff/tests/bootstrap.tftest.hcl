mock_provider "azurerm" { alias = "global" }
mock_provider "azurerm" { alias = "core_dev" }
mock_provider "azurerm" { alias = "core_prod" }
mock_provider "azurerm" { alias = "shared_network_dev" }
mock_provider "azurerm" { alias = "shared_network_prod" }

variables {
  tenant_id = "00000000-0000-0000-0000-000000000000"
  subscription_ids = {
    global              = "00000000-0000-0000-0000-000000000001", core_dev = "00000000-0000-0000-0000-000000000002",
    core_prod           = "00000000-0000-0000-0000-000000000003", shared_network_dev = "00000000-0000-0000-0000-000000000004",
    shared_network_prod = "00000000-0000-0000-0000-000000000005"
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
  runner_role_definition_names = {
    global = [], core_dev = [], core_prod = [], shared_network_dev = [], shared_network_prod = []
  }
  global_runner_role_definition_names = []
}

run "bootstrap_plan" {
  command = plan

  assert {
    condition     = length(local.external_subject_ids) == 5
    error_message = "Exactly five immutable GitHub OIDC subjects must be defined."
  }
  assert {
    condition     = length(toset(values(local.storage_account_names))) == 5
    error_message = "Every scope must have a unique state storage account."
  }
  assert {
    condition     = azurerm_storage_account.state_core_prod.blob_properties[0].versioning_enabled
    error_message = "Production state versioning must be enabled."
  }
  assert {
    condition     = !azurerm_storage_account.state_global.shared_access_key_enabled
    error_message = "Shared-key authorization must be disabled."
  }
  assert {
    condition     = azurerm_federated_identity_credential.terraform_runner_core_prod.subject == local.external_subject_ids["core_prod"]
    error_message = "The production runner must use the immutable GitHub subject."
  }
}
