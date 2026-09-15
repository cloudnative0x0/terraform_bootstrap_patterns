variable "tenant_id" {
  description = "Microsoft Entra tenant ID shared by the target subscriptions"
  type        = string
}

variable "subscription_ids" {
  description = "Pre-created Azure subscription IDs for the five platform scopes"
  type        = map(string)

  validation {
    condition = toset(keys(var.subscription_ids)) == toset([
      "global",
      "core_dev",
      "core_prod",
      "shared_network_dev",
      "shared_network_prod",
    ])
    error_message = "subscription_ids must contain exactly the five supported scopes."
  }
}

variable "location" {
  description = "Azure region used by bootstrap resources"
  type        = string
  default     = "westeurope"
}

variable "name_prefix" {
  description = "Short lowercase prefix used in Azure resource names"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,7}$", var.name_prefix))
    error_message = "name_prefix must be 2-8 lowercase alphanumeric characters starting with a letter."
  }
}

variable "github" {
  description = "Immutable GitHub identifiers used in federated identity subjects"
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
    error_message = "github.repositories must contain exactly the five supported scopes."
  }
}

variable "runner_role_definition_names" {
  description = "Explicit Azure RBAC roles for each scope runner in its own subscription"
  type        = map(set(string))

  validation {
    condition     = toset(keys(var.runner_role_definition_names)) == toset(keys(var.subscription_ids))
    error_message = "runner_role_definition_names must contain the same scope keys as subscription_ids."
  }
}

variable "global_runner_role_definition_names" {
  description = "Azure RBAC roles granted to the global runner in every non-global target subscription"
  type        = set(string)
  default     = ["Contributor", "User Access Administrator"]
}
