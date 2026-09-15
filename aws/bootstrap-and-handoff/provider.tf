provider "aws" {
  alias               = "global"
  region              = var.region
  profile             = var.bootstrap_profiles["global"]
  allowed_account_ids = [var.account_ids["global"]]
  default_tags { tags = { ManagedBy = "Terraform", Scope = "global" } }
}

provider "aws" {
  alias               = "core_dev"
  region              = var.region
  profile             = var.bootstrap_profiles["core_dev"]
  allowed_account_ids = [var.account_ids["core_dev"]]
  default_tags { tags = { ManagedBy = "Terraform", Scope = "core-dev" } }
}

provider "aws" {
  alias               = "core_prod"
  region              = var.region
  profile             = var.bootstrap_profiles["core_prod"]
  allowed_account_ids = [var.account_ids["core_prod"]]
  default_tags { tags = { ManagedBy = "Terraform", Scope = "core-prod" } }
}

provider "aws" {
  alias               = "shared_network_dev"
  region              = var.region
  profile             = var.bootstrap_profiles["shared_network_dev"]
  allowed_account_ids = [var.account_ids["shared_network_dev"]]
  default_tags { tags = { ManagedBy = "Terraform", Scope = "shared-network-dev" } }
}

provider "aws" {
  alias               = "shared_network_prod"
  region              = var.region
  profile             = var.bootstrap_profiles["shared_network_prod"]
  allowed_account_ids = [var.account_ids["shared_network_prod"]]
  default_tags { tags = { ManagedBy = "Terraform", Scope = "shared-network-prod" } }
}
