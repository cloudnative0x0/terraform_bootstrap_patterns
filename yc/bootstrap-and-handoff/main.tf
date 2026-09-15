##### Service accounts
resource "yandex_iam_service_account" "terraform_state" {
  for_each = local.scopes

  folder_id   = each.value["folder_id"]
  name        = each.value["state_manager"]
  description = "Terraform S3 backend identity for ${each.key}"
}


##### Storage
resource "yandex_storage_bucket" "terraform_state" {
  for_each = local.scopes

  folder_id     = each.value["folder_id"]
  bucket        = each.value["bucket"]
  force_destroy = false

  anonymous_access_flags {
    read        = false
    list        = false
    config_read = false
  }

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "purge-old-state-versions"
    enabled = true

    noncurrent_version_expiration {
      days = 90
    }
  }
}


##### Storage bindings
resource "yandex_storage_bucket_iam_binding" "terraform_state" {
  for_each = local.scopes

  bucket = yandex_storage_bucket.terraform_state[each.key].bucket
  role   = "storage.editor"

  members = [
    "serviceAccount:${yandex_iam_service_account.terraform_state[each.key].id}",
  ]
}

resource "time_sleep" "wait_state_iam_propagation" {
  for_each = local.scopes

  create_duration = "30s"

  depends_on = [
    yandex_storage_bucket_iam_binding.terraform_state,
  ]
}


##### Static keys
resource "yandex_iam_service_account_static_access_key" "terraform_state" {
  for_each = local.scopes

  service_account_id = yandex_iam_service_account.terraform_state[each.key].id
  description        = "S3 backend access key for ${each.key}"

  depends_on = [
    time_sleep.wait_state_iam_propagation,
  ]
}


##### Terraform runners
resource "yandex_iam_service_account" "terraform_runner" {
  for_each = local.scopes

  folder_id   = each.value["folder_id"]
  name        = each.value["runner"]
  description = "GitHub Actions Terraform runner for ${each.key}"
}

resource "yandex_resourcemanager_folder_iam_member" "global_tf_runner_editor" {
  for_each = local.global_control_folder_ids

  folder_id = each.value
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.terraform_runner["global"].id}"

  depends_on = [
    yandex_resourcemanager_folder_iam_member.global_tf_runner_resource_manager_admin,
  ]
}

resource "yandex_resourcemanager_folder_iam_member" "global_tf_runner_sa_admin" {
  for_each = local.global_control_folder_ids

  folder_id = each.value
  role      = "iam.serviceAccounts.admin"
  member    = "serviceAccount:${yandex_iam_service_account.terraform_runner["global"].id}"

  depends_on = [
    yandex_resourcemanager_folder_iam_member.global_tf_runner_resource_manager_admin,
  ]
}

resource "yandex_resourcemanager_folder_iam_member" "global_tf_runner_resource_manager_admin" {
  for_each = local.global_control_admin_folder_ids

  folder_id = each.value
  role      = "resource-manager.admin"
  member    = "serviceAccount:${yandex_iam_service_account.terraform_runner["global"].id}"
}

resource "yandex_resourcemanager_folder_iam_member" "global_tf_runner_storage_admin" {
  for_each = {
    shared_network_dev  = var.folder_ids["shared_network_dev"]
    shared_network_prod = var.folder_ids["shared_network_prod"]
  }

  folder_id = each.value
  role      = "storage.admin"
  member    = "serviceAccount:${yandex_iam_service_account.terraform_runner["global"].id}"
}

resource "yandex_resourcemanager_folder_iam_member" "workload_tf_runner_editor" {
  for_each = local.workload_folder_ids

  folder_id = each.value
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.terraform_runner[each.key].id}"
}

resource "yandex_resourcemanager_folder_iam_member" "shared_network_tf_runner_vpc_admin" {
  for_each = local.shared_network_vpc_access

  folder_id = each.value["folder_id"]
  role      = "vpc.admin"
  member    = "serviceAccount:${yandex_iam_service_account.terraform_runner[each.value["runner_scope"]].id}"
}

resource "yandex_iam_service_account_iam_member" "global_tf_runner_state_key_admin" {
  for_each = local.scopes

  service_account_id = yandex_iam_service_account.terraform_state[each.key].id
  role               = "iam.serviceAccounts.accessKeyAdmin"
  member             = "serviceAccount:${yandex_iam_service_account.terraform_runner["global"].id}"
}

resource "yandex_iam_service_account_iam_member" "global_tf_runner_federated_credential_editor" {
  for_each = local.scopes

  service_account_id = yandex_iam_service_account.terraform_runner[each.key].id
  role               = "iam.serviceAccounts.federatedCredentialEditor"
  member             = "serviceAccount:${yandex_iam_service_account.terraform_runner["global"].id}"
}

resource "yandex_resourcemanager_folder_iam_member" "global_tf_runner_wlif_admin" {
  folder_id = var.folder_ids["global"]
  role      = "iam.workloadIdentityFederations.admin"
  member    = "serviceAccount:${yandex_iam_service_account.terraform_runner["global"].id}"
}

resource "time_sleep" "wait_runner_iam_propagation" {
  create_duration = "30s"

  depends_on = [
    yandex_resourcemanager_folder_iam_member.global_tf_runner_editor,
    yandex_resourcemanager_folder_iam_member.global_tf_runner_sa_admin,
    yandex_resourcemanager_folder_iam_member.global_tf_runner_resource_manager_admin,
    yandex_resourcemanager_folder_iam_member.global_tf_runner_storage_admin,
    yandex_resourcemanager_folder_iam_member.workload_tf_runner_editor,
    yandex_resourcemanager_folder_iam_member.shared_network_tf_runner_vpc_admin,
    yandex_iam_service_account_iam_member.global_tf_runner_state_key_admin,
    yandex_iam_service_account_iam_member.global_tf_runner_federated_credential_editor,
    yandex_resourcemanager_folder_iam_member.global_tf_runner_wlif_admin,
  ]
}

##### GitHub Actions OIDC
resource "yandex_iam_workload_identity_oidc_federation" "github" {
  folder_id   = var.folder_ids["global"]
  name        = "github-actions-federation"
  description = "GitHub Actions OIDC federation"

  issuer    = "https://token.actions.githubusercontent.com"
  audiences = ["https://github.com/${var.github.organization}"]
  jwks_url  = "https://token.actions.githubusercontent.com/.well-known/jwks"
}

resource "yandex_iam_workload_identity_federated_credential" "terraform_runner" {
  for_each = var.github.repositories

  service_account_id = yandex_iam_service_account.terraform_runner[each.key].id
  federation_id      = yandex_iam_workload_identity_oidc_federation.github.id

  external_subject_id = format(
    "repo:%s@%s/%s@%s:environment:%s",
    var.github.organization,
    var.github.organization_id,
    each.value["name"],
    each.value["repository_id"],
    each.value["environment"],
  )

  depends_on = [
    time_sleep.wait_runner_iam_propagation,
  ]
}
