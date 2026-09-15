terraform {
  required_version = "~> 1.15.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.222.0"
    }

    time = {
      source  = "hashicorp/time"
      version = "~> 0.13.0"
    }
  }

  backend "local" {
    path = "terraform.tfstate"
  }
}
