mock_provider "yandex" {}
mock_provider "time" {}

variables {
  cloud_id = "b1g00000000000000000"
  zone     = "ru-central1-a"

  folder_ids = {
    global              = "b1g00000000000000001"
    core_dev            = "b1g00000000000000002"
    core_prod           = "b1g00000000000000003"
    shared_network_dev  = "b1g00000000000000004"
    shared_network_prod = "b1g00000000000000005"
  }

  github = {
    organization    = "Snowstack-AI"
    organization_id = "100000001"

    repositories = {
      global = {
        name          = "tf-global-control-plane"
        repository_id = "200000001"
        environment   = "global-platform"
      }

      core_dev = {
        name          = "tf-infrastructure"
        repository_id = "200000002"
        environment   = "core-dev"
      }

      core_prod = {
        name          = "tf-infrastructure"
        repository_id = "200000002"
        environment   = "core-prod"
      }

      shared_network_dev = {
        name          = "tf-shared-network"
        repository_id = "200000003"
        environment   = "shared-network-dev"
      }

      shared_network_prod = {
        name          = "tf-shared-network"
        repository_id = "200000003"
        environment   = "shared-network-prod"
      }
    }
  }
}

run "bootstrap_plan" {
  command = plan

  assert {
    condition     = length(local.scopes) == 5
    error_message = "Bootstrap must define exactly five initial scopes."
  }

  assert {
    condition     = !contains(keys(local.scopes), "shared_network")
    error_message = "Legacy shared_network scope must not exist."
  }

  assert {
    condition = alltrue([
      contains(keys(local.scopes), "shared_network_dev"),
      contains(keys(local.scopes), "shared_network_prod"),
    ])
    error_message = "Bootstrap must define separate dev and prod shared-network scopes."
  }

  assert {
    condition     = length(yandex_iam_service_account.terraform_state) == 5
    error_message = "Bootstrap must create one state service account per scope."
  }

  assert {
    condition     = length(yandex_storage_bucket.terraform_state) == 5
    error_message = "Bootstrap must create one state bucket per scope."
  }

  assert {
    condition     = length(yandex_iam_service_account_static_access_key.terraform_state) == 5
    error_message = "Bootstrap must create one backend access key per scope."
  }

  assert {
    condition     = length(yandex_iam_service_account.terraform_runner) == 5
    error_message = "Bootstrap must create one Terraform runner per scope."
  }

  assert {
    condition     = length(yandex_iam_workload_identity_federated_credential.terraform_runner) == 5
    error_message = "Every Terraform runner must have a GitHub OIDC credential."
  }

  assert {
    condition     = length(toset([for scope in values(local.scopes) : scope["bucket"]])) == 5
    error_message = "State bucket names must be unique."
  }

  assert {
    condition     = length(toset([for scope in values(local.scopes) : scope["state_manager"]])) == 5
    error_message = "State manager service account names must be unique."
  }

  assert {
    condition     = length(toset([for scope in values(local.scopes) : scope["runner"]])) == 5
    error_message = "Terraform runner service account names must be unique."
  }

  assert {
    condition     = length(yandex_resourcemanager_folder_iam_member.workload_tf_runner_editor) == 4
    error_message = "Every non-global runner must receive editor in its own folder."
  }

  assert {
    condition     = length(yandex_resourcemanager_folder_iam_member.global_tf_runner_storage_admin) == 2
    error_message = "The global runner must manage versioning and IAM on both shared-network state buckets."
  }

  assert {
    condition     = length(yandex_resourcemanager_folder_iam_member.shared_network_tf_runner_vpc_admin) == 2
    error_message = "Each shared-network runner must receive vpc.admin in its corresponding core folder."
  }

  assert {
    condition = (
      yandex_resourcemanager_folder_iam_member.shared_network_tf_runner_vpc_admin[
        "shared_network_dev_core_dev"
      ].folder_id == var.folder_ids["core_dev"]
    )
    error_message = "The shared-network dev runner must manage VPC resources in core-dev."
  }

  assert {
    condition = (
      yandex_resourcemanager_folder_iam_member.shared_network_tf_runner_vpc_admin[
        "shared_network_prod_core_prod"
      ].folder_id == var.folder_ids["core_prod"]
    )
    error_message = "The shared-network prod runner must manage VPC resources in core-prod."
  }

  assert {
    condition = (
      yandex_iam_workload_identity_federated_credential.terraform_runner[
        "shared_network_dev"
      ].external_subject_id ==
      "repo:Snowstack-AI@100000001/tf-shared-network@200000003:environment:shared-network-dev"
    )
    error_message = "The dev federated credential must target shared-network-dev."
  }

  assert {
    condition = (
      yandex_iam_workload_identity_federated_credential.terraform_runner[
        "shared_network_prod"
      ].external_subject_id ==
      "repo:Snowstack-AI@100000001/tf-shared-network@200000003:environment:shared-network-prod"
    )
    error_message = "The prod federated credential must target shared-network-prod."
  }
}

run "reject_incomplete_folder_map" {
  command = plan

  variables {
    folder_ids = {
      global    = "global-folder"
      core_dev  = "core-dev-folder"
      core_prod = "core-prod-folder"
    }
  }

  expect_failures = [var.folder_ids]
}
