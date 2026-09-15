locals {
  scopes = {
    global = {
      folder_id     = var.folder_ids["global"]
      bucket        = "tfstate-global-${var.folder_ids["global"]}"
      state_manager = "tf-state-manager-global"
      runner        = "tf-global-runner"
    }

    core_dev = {
      folder_id     = var.folder_ids["core_dev"]
      bucket        = "tfstate-core-dev-${var.folder_ids["core_dev"]}"
      state_manager = "tf-state-manager-core-dev"
      runner        = "tf-core-dev-runner"
    }

    core_prod = {
      folder_id     = var.folder_ids["core_prod"]
      bucket        = "tfstate-core-prod-${var.folder_ids["core_prod"]}"
      state_manager = "tf-state-manager-core-prod"
      runner        = "tf-core-prod-runner"
    }

    shared_network_dev = {
      folder_id     = var.folder_ids["shared_network_dev"]
      bucket        = "tfstate-shared-network-dev-${var.folder_ids["shared_network_dev"]}"
      state_manager = "tf-state-manager-shared-network-dev"
      runner        = "tf-shared-network-dev-runner"
    }

    shared_network_prod = {
      folder_id     = var.folder_ids["shared_network_prod"]
      bucket        = "tfstate-shared-network-prod-${var.folder_ids["shared_network_prod"]}"
      state_manager = "tf-state-manager-shared-network-prod"
      runner        = "tf-shared-network-prod-runner"
    }
  }

  workload_folder_ids = {
    core_dev            = var.folder_ids["core_dev"]
    core_prod           = var.folder_ids["core_prod"]
    shared_network_dev  = var.folder_ids["shared_network_dev"]
    shared_network_prod = var.folder_ids["shared_network_prod"]
  }

  global_control_folder_ids = {
    for scope, config in local.scopes : scope => config.folder_id
  }

  global_control_admin_folder_ids = local.global_control_folder_ids

  shared_network_vpc_access = {
    shared_network_dev_core_dev = {
      folder_id    = var.folder_ids["core_dev"]
      runner_scope = "shared_network_dev"
    }
    shared_network_prod_core_prod = {
      folder_id    = var.folder_ids["core_prod"]
      runner_scope = "shared_network_prod"
    }
  }
}
