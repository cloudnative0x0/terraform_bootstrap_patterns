output "bootstrap" {
  description = "Nebius state backends and GitHub OIDC runner identities"
  value = {
    for scope, project_id in var.project_ids : scope => {
      project_id                = project_id
      bucket                    = nebius_storage_v1_bucket.terraform_state[scope].name
      runner_service_account_id = nebius_iam_v1_service_account.terraform_runner[scope].id
      state_service_account_id  = nebius_iam_v1_service_account.terraform_state[scope].id
      state_access_key_id       = nebius_iam_v2_access_key.terraform_state[scope].status.aws_access_key_id
      state_secret_reference_id = nebius_iam_v2_access_key.terraform_state[scope].status.secret_reference_id
      external_subject_id       = local.external_subject_ids[scope]
    }
  }
}
