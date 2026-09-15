output "bootstrap" {
  description = "Bootstrap identities, state buckets and GitHub OIDC bindings"

  value = {
    terraform_state = {
      for scope, service_account in yandex_iam_service_account.terraform_state :
      scope => {
        service_account_id   = service_account["id"]
        service_account_name = service_account["name"]
        bucket               = yandex_storage_bucket.terraform_state[scope].bucket
      }
    }

    terraform_runners = {
      for scope, repository in var.github.repositories :
      scope => {
        service_account_id   = yandex_iam_service_account.terraform_runner[scope].id
        service_account_name = yandex_iam_service_account.terraform_runner[scope].name
        repository           = repository["name"]
        environment          = repository["environment"]
        external_subject_id  = yandex_iam_workload_identity_federated_credential.terraform_runner[scope].external_subject_id
      }
    }

    github_oidc_federation_id = yandex_iam_workload_identity_oidc_federation.github.id
  }
}

output "backend_credentials" {
  description = "One-time S3 backend credentials to store in the matching GitHub Environment"
  sensitive   = true

  value = {
    for scope, static_key in yandex_iam_service_account_static_access_key.terraform_state :
    scope => {
      access_key_id     = static_key["access_key"]
      secret_access_key = static_key["secret_key"]
    }
  }
}
