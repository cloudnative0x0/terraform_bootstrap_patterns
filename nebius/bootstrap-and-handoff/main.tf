resource "nebius_iam_v1_service_account" "terraform_state" {
  for_each = var.project_ids

  parent_id   = each.value
  name        = "tf-state-manager-${local.scope_names[each.key]}"
  description = "Terraform S3 backend identity for ${local.scope_names[each.key]}"
}

resource "nebius_iam_v1_service_account" "terraform_runner" {
  for_each = var.project_ids

  parent_id   = each.value
  name        = "tf-${local.scope_names[each.key]}-runner"
  description = "GitHub Actions Terraform runner for ${local.scope_names[each.key]}"
}

resource "nebius_iam_v1_group" "terraform_state" {
  for_each = var.project_ids

  parent_id = each.value
  name      = "tf-state-${local.scope_names[each.key]}"
}

resource "nebius_iam_v1_group_membership" "terraform_state" {
  for_each = var.project_ids

  parent_id = nebius_iam_v1_group.terraform_state[each.key].id
  member_id = nebius_iam_v1_service_account.terraform_state[each.key].id
}

resource "nebius_iam_v1_group" "terraform_runner" {
  for_each = var.project_ids

  parent_id = each.value
  name      = "tf-runners-${local.scope_names[each.key]}"
}

resource "nebius_iam_v1_group_membership" "terraform_runner" {
  for_each = var.project_ids

  parent_id = nebius_iam_v1_group.terraform_runner[each.key].id
  member_id = nebius_iam_v1_service_account.terraform_runner[each.key].id
}

resource "nebius_iam_v1_group" "global_runner" {
  parent_id = var.tenant_id
  name      = "tf-global-control-plane"
}

resource "nebius_iam_v1_group_membership" "global_runner" {
  parent_id = nebius_iam_v1_group.global_runner.id
  member_id = nebius_iam_v1_service_account.terraform_runner["global"].id
}

resource "nebius_storage_v1_bucket" "terraform_state" {
  for_each = var.project_ids

  parent_id             = each.value
  name                  = "${var.name_prefix}-tfstate-${local.scope_names[each.key]}"
  default_storage_class = "STANDARD"
  versioning_policy     = "ENABLED"
  object_audit_logging  = "MUTATE_ONLY"

  lifecycle_configuration = {
    rules = [{
      id     = "state-retention"
      status = "ENABLED"
      filter = { prefix = "" }
      noncurrent_version_expiration = {
        noncurrent_days           = 90
        newer_noncurrent_versions = 10
      }
      abort_incomplete_multipart_upload = {
        days_after_initiation = 7
      }
    }]
  }

  bucket_policy = {
    rules = [{
      paths    = ["*"]
      roles    = ["storage.editor"]
      group_id = nebius_iam_v1_group.terraform_state[each.key].id
    }]
  }
}

resource "nebius_iam_v2_access_key" "terraform_state" {
  for_each = var.project_ids

  parent_id = each.value
  name      = "tf-state-${local.scope_names[each.key]}"
  account = {
    service_account = {
      id = nebius_iam_v1_service_account.terraform_state[each.key].id
    }
  }
  secret_delivery_mode = "MYSTERY_BOX"

  depends_on = [nebius_iam_v1_group_membership.terraform_state]
}

resource "nebius_iam_v1_access_permit" "terraform_runner" {
  for_each = local.runner_access_permits

  parent_id   = nebius_iam_v1_group.terraform_runner[each.value["scope"]].id
  resource_id = var.project_ids[each.value["scope"]]
  role        = each.value["role"]
}

resource "nebius_iam_v1_access_permit" "global_runner" {
  for_each = local.global_access_permits

  parent_id   = nebius_iam_v1_group.global_runner.id
  resource_id = each.value["project_id"]
  role        = each.value["role"]
}

resource "nebius_iam_v1_federated_credentials" "terraform_runner" {
  for_each = var.project_ids

  parent_id            = each.value
  name                 = "github-${local.scope_names[each.key]}"
  subject_id           = nebius_iam_v1_service_account.terraform_runner[each.key].id
  federated_subject_id = local.external_subject_ids[each.key]

  oidc_provider = {
    issuer_url = "https://token.actions.githubusercontent.com"
  }

  depends_on = [
    nebius_iam_v1_group_membership.terraform_runner,
    nebius_iam_v1_access_permit.terraform_runner,
  ]
}
