output "bootstrap" {
  description = "Azure state backends and GitHub federated managed identities"
  value = {
    global = {
      subscription_id      = var.subscription_ids["global"]
      resource_group_name  = azurerm_resource_group.bootstrap_global.name
      storage_account_name = azurerm_storage_account.state_global.name
      container_name       = azurerm_storage_container.state_global.name
      runner_client_id     = azurerm_user_assigned_identity.terraform_runner_global.client_id
      state_client_id      = azurerm_user_assigned_identity.terraform_state_global.client_id
    }
    core_dev = {
      subscription_id      = var.subscription_ids["core_dev"], resource_group_name = azurerm_resource_group.bootstrap_core_dev.name,
      storage_account_name = azurerm_storage_account.state_core_dev.name, container_name = azurerm_storage_container.state_core_dev.name,
      runner_client_id     = azurerm_user_assigned_identity.terraform_runner_core_dev.client_id, state_client_id = azurerm_user_assigned_identity.terraform_state_core_dev.client_id
    }
    core_prod = {
      subscription_id      = var.subscription_ids["core_prod"], resource_group_name = azurerm_resource_group.bootstrap_core_prod.name,
      storage_account_name = azurerm_storage_account.state_core_prod.name, container_name = azurerm_storage_container.state_core_prod.name,
      runner_client_id     = azurerm_user_assigned_identity.terraform_runner_core_prod.client_id, state_client_id = azurerm_user_assigned_identity.terraform_state_core_prod.client_id
    }
    shared_network_dev = {
      subscription_id      = var.subscription_ids["shared_network_dev"], resource_group_name = azurerm_resource_group.bootstrap_shared_network_dev.name,
      storage_account_name = azurerm_storage_account.state_shared_network_dev.name, container_name = azurerm_storage_container.state_shared_network_dev.name,
      runner_client_id     = azurerm_user_assigned_identity.terraform_runner_shared_network_dev.client_id, state_client_id = azurerm_user_assigned_identity.terraform_state_shared_network_dev.client_id
    }
    shared_network_prod = {
      subscription_id      = var.subscription_ids["shared_network_prod"], resource_group_name = azurerm_resource_group.bootstrap_shared_network_prod.name,
      storage_account_name = azurerm_storage_account.state_shared_network_prod.name, container_name = azurerm_storage_container.state_shared_network_prod.name,
      runner_client_id     = azurerm_user_assigned_identity.terraform_runner_shared_network_prod.client_id, state_client_id = azurerm_user_assigned_identity.terraform_state_shared_network_prod.client_id
    }
  }
}
