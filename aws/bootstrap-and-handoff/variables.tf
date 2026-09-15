variable "account_ids" {
  description = "Pre-created AWS account IDs for the five platform scopes"
  type        = map(string)

  validation {
    condition = toset(keys(var.account_ids)) == toset([
      "global",
      "core_dev",
      "core_prod",
      "shared_network_dev",
      "shared_network_prod",
    ]) && alltrue([for id in values(var.account_ids) : can(regex("^[0-9]{12}$", id))])
    error_message = "account_ids must contain exactly the five supported scopes and every value must be a 12-digit AWS account ID."
  }
}

variable "bootstrap_profiles" {
  description = "AWS CLI profiles used only for the local bootstrap run, one per account"
  type        = map(string)

  validation {
    condition     = toset(keys(var.bootstrap_profiles)) == toset(keys(var.account_ids))
    error_message = "bootstrap_profiles must contain the same scope keys as account_ids."
  }
}

variable "region" {
  description = "AWS region for Terraform state buckets"
  type        = string
  default     = "eu-central-1"
}

variable "name_prefix" {
  description = "Lowercase prefix used for globally unique S3 bucket names"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,20}[a-z0-9]$", var.name_prefix))
    error_message = "name_prefix must be 3-22 lowercase letters, digits, or hyphens."
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

variable "runner_managed_policy_arns" {
  description = "Explicit workload policies attached to each GitHub Terraform runner"
  type        = map(set(string))

  validation {
    condition     = toset(keys(var.runner_managed_policy_arns)) == toset(keys(var.account_ids))
    error_message = "runner_managed_policy_arns must contain the same scope keys as account_ids."
  }
}

variable "global_control_managed_policy_arns" {
  description = "Policies granted to the global control-plane role in every non-global account"
  type        = set(string)
  default     = []
}
