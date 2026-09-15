# AWS Bootstrap-and-Handoff

This root bootstraps five pre-created AWS accounts: `global`, `core-dev`,
`core-prod`, `shared-network-dev`, and `shared-network-prod`.

For every account it creates a private, encrypted and versioned S3 state bucket,
a GitHub OIDC provider, a workload runner role, and a separate state role. The
runner assumes the state role only while the S3 backend is used. Native S3
lockfiles are used; DynamoDB locking is intentionally omitted because it is
deprecated by Terraform.

Each non-global account also exposes a `tf-global-control-plane` role trusted
only by the global runner. This is the handoff path used when the permanent
global IAM root must manage identities and trust policies across accounts.

## Prerequisites

- The five AWS accounts already exist under AWS Organizations/Control Tower.
- A named AWS CLI profile with bootstrap administration access exists for each account.
- GitHub environments exist and use deployment branch protection and reviewers.
- The immutable GitHub organization and repository IDs are known.

Copy `terraform.tfvars.example` to ignored `terraform.tfvars`, replace every
placeholder, then run `terraform init`, `terraform validate`, `terraform test`,
`terraform plan -out=tfplan`, and `terraform apply tfplan`.

## Handoff

In the permanent root, configure the S3 backend with the bucket and state role
from `terraform output bootstrap`:

```hcl
terraform {
  backend "s3" {
    bucket       = "<global-state-bucket>"
    key          = "iam/platform/global/tf.state"
    region       = "<region>"
    use_lockfile = true

    assume_role = {
      role_arn = "<global-state-role-arn>"
    }
  }
}
```

Copy the local state to the permanent root and run `terraform init
-migrate-state`. Replace local bootstrap profiles with the permanent CI provider
assume-role configuration before the first GitHub Actions plan. After migration,
the permanent root is the only owner of these resources.

For a non-global account, configure the corresponding aliased AWS provider to
assume the emitted `control_role_arn`. The GitHub workflow first authenticates
as the global runner through OIDC, then Terraform assumes that account-local
control role.

`runner_managed_policy_arns` and `global_control_managed_policy_arns` are
deliberately explicit. The example values are bootstrap-friendly broad policies
and must be narrowed to the API actions and resources owned by each repository.
