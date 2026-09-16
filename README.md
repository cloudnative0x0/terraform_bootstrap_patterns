# Terraform Bootstrap Patterns

Production-oriented examples of the Bootstrap-and-Handoff pattern for AWS,
Azure, Google Cloud, Nebius, and Yandex Cloud.

Every implementation creates the same logical scopes:

| Scope | Purpose |
|---|---|
| `global` | Organization-wide IAM, federation and platform control plane |
| `core_dev` | Development infrastructure for the shared core workload |
| `core_prod` | Production infrastructure for the shared core workload |
| `shared_network_dev` | Development shared networking |
| `shared_network_prod` | Production shared networking |

Cloud-native isolation boundaries differ:

| Cloud | Boundary | Remote state | GitHub identity |
|---|---|---|---|
| AWS | Account | S3 with native lockfile | IAM OIDC provider and roles |
| Azure | Subscription | Blob Storage | UAMI federated credentials |
| GCP | Project | GCS | Workload Identity Federation |
| Nebius | Project | S3-compatible Object Storage | IAM federated credentials |
| Yandex Cloud | Folder | Object Storage | Workload Identity Federation |

Each directory is a standalone Terraform root. There are no shared Terraform
modules, so an example can be copied without creating a dependency on this
repository.

## Lifecycle

1. Create the cloud organization hierarchy and attach billing outside this root.
2. Authenticate locally with a short-lived human bootstrap administrator.
3. Apply the selected cloud root while it uses local state.
4. Store the generated non-secret identifiers and required backend credentials
   in protected GitHub Environments.
5. Copy the bootstrap state and configuration into the permanent control-plane root.
6. Change the permanent root to the cloud-native remote backend and run
   `terraform init -migrate-state`.
7. Verify that the permanent root produces an empty or expected plan.
8. Never apply the local bootstrap root to the same deployment again.

The local state is sensitive even when Terraform outputs are redacted. Keep an
encrypted backup outside the repository until migration has been verified.

## Validation

Every cloud root contains Terraform native tests with mocked providers. Provider
versions are constrained in `versions.tf` and selected versions and checksums are
committed in `.terraform.lock.hcl` for `linux_amd64` and `darwin_arm64`.

## Security model

GitHub trusts are restricted to exact immutable organization ID, repository ID,
and environment subjects. State and workload identities are separated wherever
the cloud supports using separate identities for provider and backend access.
State storage is private and versioned, and destructive deletion is blocked where
the provider offers a reliable Terraform lifecycle control.

Broad bootstrap roles remain visible inputs. They make initial handoff possible,
but must be replaced incrementally by service-specific roles in the permanent
platform root. Add granular grants first, test the pipelines, and remove broad
roles last to avoid locking the control plane out of its own IAM resources.
