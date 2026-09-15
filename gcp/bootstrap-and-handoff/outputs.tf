output "bootstrap" {
  description = "GCP state backends and GitHub Workload Identity Federation bindings"
  value = {
    for scope, project_id in var.project_ids : scope => {
      project_id                 = project_id
      bucket                     = google_storage_bucket.terraform_state[scope].name
      runner_service_account     = google_service_account.terraform_runner[scope].email
      state_service_account      = google_service_account.terraform_state[scope].email
      workload_identity_provider = google_iam_workload_identity_pool_provider.github[scope].name
      external_subject_id        = local.external_subject_ids[scope]
    }
  }
}
