# Google Cloud Bootstrap-and-Handoff

This root bootstraps five pre-created Google Cloud projects. It enables the
required APIs and creates a private versioned GCS state bucket, a state service
account, a workload runner service account, and an isolated GitHub Workload
Identity Pool per scope. Each pool accepts only one exact immutable GitHub
environment subject.

Authenticate locally with Application Default Credentials, copy
`terraform.tfvars.example` to ignored `terraform.tfvars`, and run `terraform
init`, `terraform validate`, `terraform test`, `terraform plan -out=tfplan`, and
`terraform apply tfplan`.

Projects, billing attachment and organization/folder policies are prerequisites.
The bootstrap operator needs service usage, storage, service account, workload
identity federation and project IAM administration permissions.

## Handoff

Authenticate GitHub Actions as the runner service account. Configure the
permanent root backend to impersonate its separate state service account:

```hcl
terraform {
  backend "gcs" {
    bucket                      = "<global-state-bucket>"
    prefix                      = "iam/platform/global"
    impersonate_service_account = "<global-state-service-account>"
  }
}
```

Copy the local state to the permanent root and run `terraform init
-migrate-state`. After migration, only the permanent root owns these resources.

The sample project roles are bootstrap-friendly. Replace `roles/editor` and the
global administration set with the exact predefined or custom roles required by
each Terraform repository.
