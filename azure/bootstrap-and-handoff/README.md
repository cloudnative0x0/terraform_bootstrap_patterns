# Azure Bootstrap-and-Handoff

This root bootstraps five pre-created Azure subscriptions in one Microsoft Entra
tenant. Each subscription receives a bootstrap resource group, a private and
versioned Blob Storage backend, and separate user-assigned managed identities
for Terraform state and workload operations. Both identities trust one exact
immutable GitHub environment subject and do not use client secrets.

Authenticate locally with `az login`, copy `terraform.tfvars.example` to ignored
`terraform.tfvars`, and run `terraform init`, `terraform validate`, `terraform
test`, `terraform plan -out=tfplan`, and `terraform apply tfplan`.

The bootstrap operator needs resource administration, role-assignment, and
Storage Blob Data Owner permissions in all five subscriptions. The subscriptions
and billing hierarchy are prerequisites.

## Handoff

Configure the permanent root with a partial AzureRM backend:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "<bootstrap-resource-group>"
    storage_account_name = "<state-storage-account>"
    container_name       = "tfstate"
    key                  = "iam/platform/global/tf.state"
    use_oidc             = true
    use_azuread_auth     = true
    tenant_id            = "<tenant-id>"
    subscription_id      = "<global-subscription-id>"
    client_id            = "<global-state-client-id>"
  }
}
```

Use the runner client ID for the AzureRM provider and the state client ID for the
backend. Copy the local state to the permanent root and run `terraform init
-migrate-state`. After migration, only the permanent root owns bootstrap resources.

The sample RBAC roles are intentionally visible inputs. Replace broad Contributor
and User Access Administrator grants with resource-specific custom roles as the
platform roots stabilize.
