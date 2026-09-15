variable "cloud_id" {
  type        = string
  description = "Yandex Cloud ID"
}

variable "zone" {
  type        = string
  description = "Yandex Cloud availability zone"
}

variable "folder_ids" {
  type        = map(string)
  description = "Existing Yandex Cloud folder IDs"

  validation {
    condition = toset(keys(var.folder_ids)) == toset([
      "global",
      "core_dev",
      "core_prod",
      "shared_network_dev",
      "shared_network_prod",
    ])

    error_message = "folder_ids must contain global, core_dev, core_prod, shared_network_dev and shared_network_prod."
  }
}

variable "github" {
  description = "Immutable GitHub identifiers used in Yandex Cloud OIDC subjects"

  type = object({
    organization    = string
    organization_id = string
    repositories = map(object({
      name          = string
      repository_id = string
      environment   = string
    }))
  })

  validation {
    condition = toset(keys(var.github.repositories)) == toset([
      "global",
      "core_dev",
      "core_prod",
      "shared_network_dev",
      "shared_network_prod",
    ])

    error_message = "github.repositories must contain global, core_dev, core_prod, shared_network_dev and shared_network_prod."
  }
}
