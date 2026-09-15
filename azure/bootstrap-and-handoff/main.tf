resource "azurerm_resource_group" "bootstrap_global" {
  provider = azurerm.global
  name     = "rg-${var.name_prefix}-${local.scope_names["global"]}-bootstrap"
  location = var.location

  tags = { managed_by = "terraform", scope = local.scope_names["global"] }
}

resource "azurerm_storage_account" "state_global" {
  provider = azurerm.global

  name                = local.storage_account_names["global"]
  resource_group_name = azurerm_resource_group.bootstrap_global.name
  location            = azurerm_resource_group.bootstrap_global.location

  account_tier                      = "Standard"
  account_replication_type          = "GRS"
  min_tls_version                   = "TLS1_2"
  shared_access_key_enabled         = false
  allow_nested_items_to_be_public   = false
  infrastructure_encryption_enabled = true

  blob_properties {
    versioning_enabled  = true
    change_feed_enabled = true

    delete_retention_policy { days = 90 }
    container_delete_retention_policy { days = 90 }
  }

  tags = { managed_by = "terraform", scope = local.scope_names["global"] }

  lifecycle { prevent_destroy = true }
}

resource "azurerm_storage_container" "state_global" {
  provider = azurerm.global

  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.state_global.id
  container_access_type = "private"
}

resource "azurerm_user_assigned_identity" "terraform_state_global" {
  provider = azurerm.global

  name                = "id-tf-state-${local.scope_names["global"]}"
  location            = azurerm_resource_group.bootstrap_global.location
  resource_group_name = azurerm_resource_group.bootstrap_global.name
  tags                = { managed_by = "terraform", scope = local.scope_names["global"] }
}

resource "azurerm_user_assigned_identity" "terraform_runner_global" {
  provider = azurerm.global

  name                = "id-tf-runner-${local.scope_names["global"]}"
  location            = azurerm_resource_group.bootstrap_global.location
  resource_group_name = azurerm_resource_group.bootstrap_global.name
  tags                = { managed_by = "terraform", scope = local.scope_names["global"] }
}

resource "azurerm_federated_identity_credential" "terraform_state_global" {
  provider = azurerm.global

  name                      = "github-${local.scope_names["global"]}-state"
  user_assigned_identity_id = azurerm_user_assigned_identity.terraform_state_global.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://token.actions.githubusercontent.com"
  subject                   = local.external_subject_ids["global"]
}

resource "azurerm_federated_identity_credential" "terraform_runner_global" {
  provider = azurerm.global

  name                      = "github-${local.scope_names["global"]}-runner"
  user_assigned_identity_id = azurerm_user_assigned_identity.terraform_runner_global.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://token.actions.githubusercontent.com"
  subject                   = local.external_subject_ids["global"]
}

resource "azurerm_role_assignment" "terraform_state_global" {
  provider = azurerm.global

  scope                = azurerm_storage_account.state_global.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.terraform_state_global.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "terraform_runner_global" {
  provider             = azurerm.global
  for_each             = var.runner_role_definition_names["global"]
  scope                = "/subscriptions/${var.subscription_ids["global"]}"
  role_definition_name = each.value
  principal_id         = azurerm_user_assigned_identity.terraform_runner_global.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_resource_group" "bootstrap_core_dev" {
  provider = azurerm.core_dev
  name     = "rg-${var.name_prefix}-${local.scope_names["core_dev"]}-bootstrap"
  location = var.location

  tags = { managed_by = "terraform", scope = local.scope_names["core_dev"] }
}

resource "azurerm_storage_account" "state_core_dev" {
  provider = azurerm.core_dev

  name                = local.storage_account_names["core_dev"]
  resource_group_name = azurerm_resource_group.bootstrap_core_dev.name
  location            = azurerm_resource_group.bootstrap_core_dev.location

  account_tier                      = "Standard"
  account_replication_type          = "GRS"
  min_tls_version                   = "TLS1_2"
  shared_access_key_enabled         = false
  allow_nested_items_to_be_public   = false
  infrastructure_encryption_enabled = true

  blob_properties {
    versioning_enabled  = true
    change_feed_enabled = true

    delete_retention_policy { days = 90 }
    container_delete_retention_policy { days = 90 }
  }

  tags = { managed_by = "terraform", scope = local.scope_names["core_dev"] }

  lifecycle { prevent_destroy = true }
}

resource "azurerm_storage_container" "state_core_dev" {
  provider = azurerm.core_dev

  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.state_core_dev.id
  container_access_type = "private"
}

resource "azurerm_user_assigned_identity" "terraform_state_core_dev" {
  provider = azurerm.core_dev

  name                = "id-tf-state-${local.scope_names["core_dev"]}"
  location            = azurerm_resource_group.bootstrap_core_dev.location
  resource_group_name = azurerm_resource_group.bootstrap_core_dev.name
  tags                = { managed_by = "terraform", scope = local.scope_names["core_dev"] }
}

resource "azurerm_user_assigned_identity" "terraform_runner_core_dev" {
  provider = azurerm.core_dev

  name                = "id-tf-runner-${local.scope_names["core_dev"]}"
  location            = azurerm_resource_group.bootstrap_core_dev.location
  resource_group_name = azurerm_resource_group.bootstrap_core_dev.name
  tags                = { managed_by = "terraform", scope = local.scope_names["core_dev"] }
}

resource "azurerm_federated_identity_credential" "terraform_state_core_dev" {
  provider = azurerm.core_dev

  name                      = "github-${local.scope_names["core_dev"]}-state"
  user_assigned_identity_id = azurerm_user_assigned_identity.terraform_state_core_dev.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://token.actions.githubusercontent.com"
  subject                   = local.external_subject_ids["core_dev"]
}

resource "azurerm_federated_identity_credential" "terraform_runner_core_dev" {
  provider = azurerm.core_dev

  name                      = "github-${local.scope_names["core_dev"]}-runner"
  user_assigned_identity_id = azurerm_user_assigned_identity.terraform_runner_core_dev.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://token.actions.githubusercontent.com"
  subject                   = local.external_subject_ids["core_dev"]
}

resource "azurerm_role_assignment" "terraform_state_core_dev" {
  provider = azurerm.core_dev

  scope                = azurerm_storage_account.state_core_dev.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.terraform_state_core_dev.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "terraform_runner_core_dev" {
  provider             = azurerm.core_dev
  for_each             = var.runner_role_definition_names["core_dev"]
  scope                = "/subscriptions/${var.subscription_ids["core_dev"]}"
  role_definition_name = each.value
  principal_id         = azurerm_user_assigned_identity.terraform_runner_core_dev.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "global_runner_in_core_dev" {
  provider = azurerm.core_dev
  for_each = var.global_runner_role_definition_names

  scope                = "/subscriptions/${var.subscription_ids["core_dev"]}"
  role_definition_name = each.value
  principal_id         = azurerm_user_assigned_identity.terraform_runner_global.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_resource_group" "bootstrap_core_prod" {
  provider = azurerm.core_prod
  name     = "rg-${var.name_prefix}-${local.scope_names["core_prod"]}-bootstrap"
  location = var.location

  tags = { managed_by = "terraform", scope = local.scope_names["core_prod"] }
}

resource "azurerm_storage_account" "state_core_prod" {
  provider = azurerm.core_prod

  name                = local.storage_account_names["core_prod"]
  resource_group_name = azurerm_resource_group.bootstrap_core_prod.name
  location            = azurerm_resource_group.bootstrap_core_prod.location

  account_tier                      = "Standard"
  account_replication_type          = "GRS"
  min_tls_version                   = "TLS1_2"
  shared_access_key_enabled         = false
  allow_nested_items_to_be_public   = false
  infrastructure_encryption_enabled = true

  blob_properties {
    versioning_enabled  = true
    change_feed_enabled = true

    delete_retention_policy { days = 90 }
    container_delete_retention_policy { days = 90 }
  }

  tags = { managed_by = "terraform", scope = local.scope_names["core_prod"] }

  lifecycle { prevent_destroy = true }
}

resource "azurerm_storage_container" "state_core_prod" {
  provider = azurerm.core_prod

  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.state_core_prod.id
  container_access_type = "private"
}

resource "azurerm_user_assigned_identity" "terraform_state_core_prod" {
  provider = azurerm.core_prod

  name                = "id-tf-state-${local.scope_names["core_prod"]}"
  location            = azurerm_resource_group.bootstrap_core_prod.location
  resource_group_name = azurerm_resource_group.bootstrap_core_prod.name
  tags                = { managed_by = "terraform", scope = local.scope_names["core_prod"] }
}

resource "azurerm_user_assigned_identity" "terraform_runner_core_prod" {
  provider = azurerm.core_prod

  name                = "id-tf-runner-${local.scope_names["core_prod"]}"
  location            = azurerm_resource_group.bootstrap_core_prod.location
  resource_group_name = azurerm_resource_group.bootstrap_core_prod.name
  tags                = { managed_by = "terraform", scope = local.scope_names["core_prod"] }
}

resource "azurerm_federated_identity_credential" "terraform_state_core_prod" {
  provider = azurerm.core_prod

  name                      = "github-${local.scope_names["core_prod"]}-state"
  user_assigned_identity_id = azurerm_user_assigned_identity.terraform_state_core_prod.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://token.actions.githubusercontent.com"
  subject                   = local.external_subject_ids["core_prod"]
}

resource "azurerm_federated_identity_credential" "terraform_runner_core_prod" {
  provider = azurerm.core_prod

  name                      = "github-${local.scope_names["core_prod"]}-runner"
  user_assigned_identity_id = azurerm_user_assigned_identity.terraform_runner_core_prod.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://token.actions.githubusercontent.com"
  subject                   = local.external_subject_ids["core_prod"]
}

resource "azurerm_role_assignment" "terraform_state_core_prod" {
  provider = azurerm.core_prod

  scope                = azurerm_storage_account.state_core_prod.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.terraform_state_core_prod.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "terraform_runner_core_prod" {
  provider             = azurerm.core_prod
  for_each             = var.runner_role_definition_names["core_prod"]
  scope                = "/subscriptions/${var.subscription_ids["core_prod"]}"
  role_definition_name = each.value
  principal_id         = azurerm_user_assigned_identity.terraform_runner_core_prod.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "global_runner_in_core_prod" {
  provider = azurerm.core_prod
  for_each = var.global_runner_role_definition_names

  scope                = "/subscriptions/${var.subscription_ids["core_prod"]}"
  role_definition_name = each.value
  principal_id         = azurerm_user_assigned_identity.terraform_runner_global.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_resource_group" "bootstrap_shared_network_dev" {
  provider = azurerm.shared_network_dev
  name     = "rg-${var.name_prefix}-${local.scope_names["shared_network_dev"]}-bootstrap"
  location = var.location

  tags = { managed_by = "terraform", scope = local.scope_names["shared_network_dev"] }
}

resource "azurerm_storage_account" "state_shared_network_dev" {
  provider = azurerm.shared_network_dev

  name                = local.storage_account_names["shared_network_dev"]
  resource_group_name = azurerm_resource_group.bootstrap_shared_network_dev.name
  location            = azurerm_resource_group.bootstrap_shared_network_dev.location

  account_tier                      = "Standard"
  account_replication_type          = "GRS"
  min_tls_version                   = "TLS1_2"
  shared_access_key_enabled         = false
  allow_nested_items_to_be_public   = false
  infrastructure_encryption_enabled = true

  blob_properties {
    versioning_enabled  = true
    change_feed_enabled = true

    delete_retention_policy { days = 90 }
    container_delete_retention_policy { days = 90 }
  }

  tags = { managed_by = "terraform", scope = local.scope_names["shared_network_dev"] }

  lifecycle { prevent_destroy = true }
}

resource "azurerm_storage_container" "state_shared_network_dev" {
  provider = azurerm.shared_network_dev

  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.state_shared_network_dev.id
  container_access_type = "private"
}

resource "azurerm_user_assigned_identity" "terraform_state_shared_network_dev" {
  provider = azurerm.shared_network_dev

  name                = "id-tf-state-${local.scope_names["shared_network_dev"]}"
  location            = azurerm_resource_group.bootstrap_shared_network_dev.location
  resource_group_name = azurerm_resource_group.bootstrap_shared_network_dev.name
  tags                = { managed_by = "terraform", scope = local.scope_names["shared_network_dev"] }
}

resource "azurerm_user_assigned_identity" "terraform_runner_shared_network_dev" {
  provider = azurerm.shared_network_dev

  name                = "id-tf-runner-${local.scope_names["shared_network_dev"]}"
  location            = azurerm_resource_group.bootstrap_shared_network_dev.location
  resource_group_name = azurerm_resource_group.bootstrap_shared_network_dev.name
  tags                = { managed_by = "terraform", scope = local.scope_names["shared_network_dev"] }
}

resource "azurerm_federated_identity_credential" "terraform_state_shared_network_dev" {
  provider = azurerm.shared_network_dev

  name                      = "github-${local.scope_names["shared_network_dev"]}-state"
  user_assigned_identity_id = azurerm_user_assigned_identity.terraform_state_shared_network_dev.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://token.actions.githubusercontent.com"
  subject                   = local.external_subject_ids["shared_network_dev"]
}

resource "azurerm_federated_identity_credential" "terraform_runner_shared_network_dev" {
  provider = azurerm.shared_network_dev

  name                      = "github-${local.scope_names["shared_network_dev"]}-runner"
  user_assigned_identity_id = azurerm_user_assigned_identity.terraform_runner_shared_network_dev.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://token.actions.githubusercontent.com"
  subject                   = local.external_subject_ids["shared_network_dev"]
}

resource "azurerm_role_assignment" "terraform_state_shared_network_dev" {
  provider = azurerm.shared_network_dev

  scope                = azurerm_storage_account.state_shared_network_dev.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.terraform_state_shared_network_dev.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "terraform_runner_shared_network_dev" {
  provider             = azurerm.shared_network_dev
  for_each             = var.runner_role_definition_names["shared_network_dev"]
  scope                = "/subscriptions/${var.subscription_ids["shared_network_dev"]}"
  role_definition_name = each.value
  principal_id         = azurerm_user_assigned_identity.terraform_runner_shared_network_dev.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "global_runner_in_shared_network_dev" {
  provider = azurerm.shared_network_dev
  for_each = var.global_runner_role_definition_names

  scope                = "/subscriptions/${var.subscription_ids["shared_network_dev"]}"
  role_definition_name = each.value
  principal_id         = azurerm_user_assigned_identity.terraform_runner_global.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_resource_group" "bootstrap_shared_network_prod" {
  provider = azurerm.shared_network_prod
  name     = "rg-${var.name_prefix}-${local.scope_names["shared_network_prod"]}-bootstrap"
  location = var.location

  tags = { managed_by = "terraform", scope = local.scope_names["shared_network_prod"] }
}

resource "azurerm_storage_account" "state_shared_network_prod" {
  provider = azurerm.shared_network_prod

  name                = local.storage_account_names["shared_network_prod"]
  resource_group_name = azurerm_resource_group.bootstrap_shared_network_prod.name
  location            = azurerm_resource_group.bootstrap_shared_network_prod.location

  account_tier                      = "Standard"
  account_replication_type          = "GRS"
  min_tls_version                   = "TLS1_2"
  shared_access_key_enabled         = false
  allow_nested_items_to_be_public   = false
  infrastructure_encryption_enabled = true

  blob_properties {
    versioning_enabled  = true
    change_feed_enabled = true

    delete_retention_policy { days = 90 }
    container_delete_retention_policy { days = 90 }
  }

  tags = { managed_by = "terraform", scope = local.scope_names["shared_network_prod"] }

  lifecycle { prevent_destroy = true }
}

resource "azurerm_storage_container" "state_shared_network_prod" {
  provider = azurerm.shared_network_prod

  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.state_shared_network_prod.id
  container_access_type = "private"
}

resource "azurerm_user_assigned_identity" "terraform_state_shared_network_prod" {
  provider = azurerm.shared_network_prod

  name                = "id-tf-state-${local.scope_names["shared_network_prod"]}"
  location            = azurerm_resource_group.bootstrap_shared_network_prod.location
  resource_group_name = azurerm_resource_group.bootstrap_shared_network_prod.name
  tags                = { managed_by = "terraform", scope = local.scope_names["shared_network_prod"] }
}

resource "azurerm_user_assigned_identity" "terraform_runner_shared_network_prod" {
  provider = azurerm.shared_network_prod

  name                = "id-tf-runner-${local.scope_names["shared_network_prod"]}"
  location            = azurerm_resource_group.bootstrap_shared_network_prod.location
  resource_group_name = azurerm_resource_group.bootstrap_shared_network_prod.name
  tags                = { managed_by = "terraform", scope = local.scope_names["shared_network_prod"] }
}

resource "azurerm_federated_identity_credential" "terraform_state_shared_network_prod" {
  provider = azurerm.shared_network_prod

  name                      = "github-${local.scope_names["shared_network_prod"]}-state"
  user_assigned_identity_id = azurerm_user_assigned_identity.terraform_state_shared_network_prod.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://token.actions.githubusercontent.com"
  subject                   = local.external_subject_ids["shared_network_prod"]
}

resource "azurerm_federated_identity_credential" "terraform_runner_shared_network_prod" {
  provider = azurerm.shared_network_prod

  name                      = "github-${local.scope_names["shared_network_prod"]}-runner"
  user_assigned_identity_id = azurerm_user_assigned_identity.terraform_runner_shared_network_prod.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://token.actions.githubusercontent.com"
  subject                   = local.external_subject_ids["shared_network_prod"]
}

resource "azurerm_role_assignment" "terraform_state_shared_network_prod" {
  provider = azurerm.shared_network_prod

  scope                = azurerm_storage_account.state_shared_network_prod.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.terraform_state_shared_network_prod.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "terraform_runner_shared_network_prod" {
  provider             = azurerm.shared_network_prod
  for_each             = var.runner_role_definition_names["shared_network_prod"]
  scope                = "/subscriptions/${var.subscription_ids["shared_network_prod"]}"
  role_definition_name = each.value
  principal_id         = azurerm_user_assigned_identity.terraform_runner_shared_network_prod.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "global_runner_in_shared_network_prod" {
  provider = azurerm.shared_network_prod
  for_each = var.global_runner_role_definition_names

  scope                = "/subscriptions/${var.subscription_ids["shared_network_prod"]}"
  role_definition_name = each.value
  principal_id         = azurerm_user_assigned_identity.terraform_runner_global.principal_id
  principal_type       = "ServicePrincipal"
}
