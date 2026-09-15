variable "tenant_id" {
  description = "Nebius tenant containing all target projects"
  type        = string
}

variable "project_ids" {
  description = "Pre-created Nebius project IDs for the five platform scopes"
  type        = map(string)

  validation {
    condition = toset(keys(var.project_ids)) == toset([
      "global",
      "core_dev",
      "core_prod",
      "shared_network_dev",
      "shared_network_prod",
    ])
    error_message = "project_ids must contain exactly the five supported scopes."
  }
}

variable "region" {
  description = "Nebius region used by state buckets and the S3 backend"
  type        = string
  default     = "eu-north1"
}

variable "name_prefix" {
  description = "Lowercase prefix used for globally unique Object Storage bucket names"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,15}[a-z0-9]$", var.name_prefix))
    error_message = "name_prefix must be 3-17 lowercase letters, digits, or hyphens."
  }
}

variable "github" {
  description = "Immutable GitHub identifiers used in OIDC subjects"
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

variable "runner_roles" {
  description = "Explicit Nebius roles granted to each scope runner in its own project"
  type        = map(set(string))

  validation {
    condition     = toset(keys(var.runner_roles)) == toset(keys(var.project_ids))
    error_message = "runner_roles must contain the same scope keys as project_ids."
  }
}

variable "global_runner_roles" {
  description = "Nebius roles granted to the global runner in every project"
  type        = set(string)
  default     = ["admin"]
}
