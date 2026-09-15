# Yandex Cloud bootstrap

This Terraform root prepares the initial control-plane identities and remote
state storage for a new Yandex Cloud deployment.

It is intended for a new cloud only. Do not apply it to an existing deployment
after its state has been migrated to `yc/iam/platform`.

## Ownership boundary

The bootstrap root owns the initial creation of:

- the GitHub Actions workload identity federation;
- one Terraform runner service account per scope;
- one Terraform state manager service account per scope;
- one versioned Object Storage bucket per scope;
- one static S3 backend access key per state manager;
- the initial IAM bindings required by the Terraform repositories.

It does not create or delete cloud folders, networks, compute resources,
databases, monitoring, billing alerts, or product resources.

The following folders must exist before bootstrap:

- `global-platform`;
- `core-dev`;
- `core-prod`;
- `shared-network-dev`;
- `shared-network-prod`.

Disable automatic default-network creation when creating these folders.

## Authentication

Authenticate as a human bootstrap administrator using a temporary Yandex Cloud
IAM token or an existing `yc` CLI profile. Do not store the token in
`terraform.tfvars`.

The operator must be able to create service accounts, IAM bindings, workload
identity federations, buckets, bucket policies, bucket versioning, and static
access keys in all target folders.

## Initial deployment

Create the local input file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Replace every placeholder with the immutable cloud, folder, GitHub organization,
repository, and environment identifiers.

Run:

```bash
terraform init
terraform fmt -check
terraform validate
terraform test
terraform plan -out=tfplan
terraform apply tfplan
```

The local `terraform.tfstate` contains backend secret access keys. It must
never be committed or shared through an unencrypted channel.

## Outputs and GitHub environments

The non-sensitive inventory is available through:

```bash
terraform output bootstrap
```

Backend credentials are intentionally isolated in a sensitive output:

```bash
terraform output backend_credentials
```

Store each credential pair in the matching GitHub Environment as:

- `TF_STATE_ACCESS_KEY_ID`;
- `TF_STATE_SECRET_ACCESS_KEY`.

Do not redirect the sensitive output to a file inside the repository.

## State migration

Before migration, create a protected backup outside the repository:

```bash
umask 077
cp terraform.tfstate ../../../terraform-bootstrap-state.backup
```

Update `yc/iam/platform/backend.tf` so that its bucket points to the new
global-platform state bucket.

Copy the local state into the active root and initialize the remote backend:

```bash
cp terraform.tfstate ../iam/platform/terraform.tfstate
terraform -chdir=../iam/platform init -migrate-state
terraform -chdir=../iam/platform plan
```

Review the plan before continuing. After successful migration,
`yc/iam/platform` is the only active owner of these resources. Keep
`yc/bootstrap` as a versioned template and do not apply it again to the same
cloud.

## Recovery

Keep one MFA-protected human break-glass administrator outside Terraform
automation. This identity is used only to restore IAM, federation, or state
access when GitHub OIDC or the global Terraform runner is unavailable.

If bootstrap stops after creating only some resources, do not delete resources
manually. Preserve the local state, fix the cause, run `terraform plan`, and
continue the same apply.
