resource "google_project_service" "required" {
  for_each = local.project_services

  project            = each.value["project_id"]
  service            = each.value["service"]
  disable_on_destroy = false
}

resource "google_storage_bucket" "terraform_state" {
  for_each = var.project_ids

  project  = each.value
  name     = "${var.name_prefix}-tfstate-${local.scope_names[each.key]}-${each.value}"
  location = var.region

  force_destroy               = false
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning { enabled = true }

  lifecycle_rule {
    condition {
      days_since_noncurrent_time = 90
      num_newer_versions         = 10
    }
    action { type = "Delete" }
  }

  lifecycle { prevent_destroy = true }

  depends_on = [google_project_service.required]
}

resource "google_service_account" "terraform_state" {
  for_each = var.project_ids

  project      = each.value
  account_id   = "tf-state-${replace(local.scope_names[each.key], "-", "")}"
  display_name = "Terraform state manager for ${local.scope_names[each.key]}"

  depends_on = [google_project_service.required]
}

resource "google_service_account" "terraform_runner" {
  for_each = var.project_ids

  project      = each.value
  account_id   = "tf-runner-${replace(local.scope_names[each.key], "-", "")}"
  display_name = "GitHub Terraform runner for ${local.scope_names[each.key]}"

  depends_on = [google_project_service.required]
}

resource "google_storage_bucket_iam_member" "terraform_state" {
  for_each = var.project_ids

  bucket = google_storage_bucket.terraform_state[each.key].name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.terraform_state[each.key].email}"
}

resource "google_iam_workload_identity_pool" "github" {
  for_each = var.project_ids

  project                   = var.project_ids["global"]
  workload_identity_pool_id = "github-${replace(local.scope_names[each.key], "_", "-")}"
  display_name              = "GitHub ${local.scope_names[each.key]}"
  description               = "GitHub Actions identities for ${local.scope_names[each.key]}"

  depends_on = [google_project_service.required]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  for_each = var.project_ids

  project                            = var.project_ids["global"]
  workload_identity_pool_id          = google_iam_workload_identity_pool.github[each.key].workload_identity_pool_id
  workload_identity_pool_provider_id = "github"
  display_name                       = "GitHub Actions"

  attribute_mapping = {
    "google.subject"                = "assertion.sub"
    "attribute.repository_id"       = "assertion.repository_id"
    "attribute.repository_owner_id" = "assertion.repository_owner_id"
  }

  attribute_condition = "assertion.sub == '${local.external_subject_ids[each.key]}'"

  oidc { issuer_uri = "https://token.actions.githubusercontent.com" }
}

resource "google_service_account_iam_member" "github_runner" {
  for_each = var.project_ids

  service_account_id = google_service_account.terraform_runner[each.key].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github[each.key].name}/*"
}

resource "google_service_account_iam_member" "runner_impersonates_state" {
  for_each = var.project_ids

  service_account_id = google_service_account.terraform_state[each.key].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.terraform_runner[each.key].email}"
}

resource "google_project_iam_member" "terraform_runner" {
  for_each = local.runner_roles

  project = var.project_ids[each.value["scope"]]
  role    = each.value["role"]
  member  = "serviceAccount:${google_service_account.terraform_runner[each.value["scope"]].email}"
}

resource "google_project_iam_member" "global_runner" {
  for_each = local.global_runner_roles

  project = each.value["project_id"]
  role    = each.value["role"]
  member  = "serviceAccount:${google_service_account.terraform_runner["global"].email}"
}
