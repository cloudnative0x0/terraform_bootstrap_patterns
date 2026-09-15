variable "project_ids" {
  description = "Pre-created Google Cloud project IDs for the five platform scopes"
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
  description = "Default Google Cloud region"
  type        = string
  default     = "europe-west1"
}

variable "name_prefix" {
  description = "Lowercase prefix used for globally unique Cloud Storage bucket names"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,15}[a-z0-9]$", var.name_prefix))
    error_message = "name_prefix must be 3-17 lowercase letters, digits, or hyphens."
  }
}

variable "github" {
  description = "Immutable GitHub identifiers used in workload identity conditions"
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

variable "runner_project_roles" {
  description = "Explicit project roles for each scope runner"
  type        = map(set(string))

  validation {
    condition     = toset(keys(var.runner_project_roles)) == toset(keys(var.project_ids))
    error_message = "runner_project_roles must contain the same scope keys as project_ids."
  }
}

variable "global_runner_project_roles" {
  description = "Roles granted to the global runner in every target project"
  type        = set(string)
  default = [
    "roles/resourcemanager.projectIamAdmin",
    "roles/iam.serviceAccountAdmin",
    "roles/iam.workloadIdentityPoolAdmin",
    "roles/storage.admin",
  ]
}
