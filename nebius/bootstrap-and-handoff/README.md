# Nebius Bootstrap-and-Handoff

This root bootstraps five pre-created Nebius projects in one tenant. It creates a
versioned Object Storage bucket, state service account and group, workload runner
service account and group, and an exact GitHub OIDC federated credential per
scope. State access keys use the provider-recommended `MYSTERY_BOX` delivery mode,
so their secrets are not stored directly in Terraform state.

Authenticate locally through a Nebius CLI profile or a temporary user token.
Copy `terraform.tfvars.example` to ignored `terraform.tfvars`, then run
`terraform init`, `terraform validate`, `terraform test`, `terraform plan
-out=tfplan`, and `terraform apply tfplan`.

Projects and billing are prerequisites. Retrieve each access-key secret through
its returned MysteryBox secret reference and store it once in the matching
GitHub Environment.

## Handoff

Configure the permanent root with a partial S3 backend:

```hcl
terraform {
  backend "s3" {
    bucket       = "<global-state-bucket>"
    key          = "iam/platform/global/tf.state"
    region       = "eu-north1"
    use_lockfile = true

    endpoints = { s3 = "https://storage.eu-north1.nebius.cloud" }

    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
  }
}
```

Supply the AWS-like access-key ID and secret through environment variables.
Copy the local state to the permanent root and run `terraform init
-migrate-state`. After migration, only the permanent root owns these resources.

Nebius currently exposes a small set of granular infrastructure roles. The
sample therefore uses `editor` for scope runners and `admin` for the global IAM
runner. Revisit these grants whenever new service-specific roles become available.
