terraform {
  required_version = "~> 1.15.0"

  required_providers {
    nebius = {
      source  = "nebius/nebius"
      version = "~> 0.6.51"
    }
  }

  backend "local" {
    path = "terraform.tfstate"
  }
}
