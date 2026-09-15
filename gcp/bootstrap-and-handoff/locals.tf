locals {
  scope_names = {
    global              = "global"
    core_dev            = "core-dev"
    core_prod           = "core-prod"
    shared_network_dev  = "shared-network-dev"
    shared_network_prod = "shared-network-prod"
  }

  external_subject_ids = {
    for scope, repository in var.github.repositories : scope => format(
      "repo:%s@%s/%s@%s:environment:%s",
      var.github.organization,
      var.github.organization_id,
      repository["name"],
      repository["repository_id"],
      repository["environment"],
    )
  }

  required_services = toset([
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
    "storage.googleapis.com",
  ])

  project_services = merge([
    for scope, project_id in var.project_ids : {
      for service in local.required_services : "${scope}:${service}" => {
        scope      = scope
        project_id = project_id
        service    = service
      }
    }
  ]...)

  runner_roles = merge([
    for scope, roles in var.runner_project_roles : {
      for role in roles : "${scope}:${role}" => {
        scope = scope
        role  = role
      }
    }
  ]...)

  global_runner_roles = merge([
    for scope, project_id in var.project_ids : {
      for role in var.global_runner_project_roles : "${scope}:${role}" => {
        project_id = project_id
        role       = role
      }
    }
  ]...)
}
