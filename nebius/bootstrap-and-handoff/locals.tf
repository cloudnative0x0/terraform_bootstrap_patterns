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

  runner_access_permits = merge([
    for scope, roles in var.runner_roles : {
      for role in roles : "${scope}:${role}" => {
        scope = scope
        role  = role
      }
    }
  ]...)

  global_access_permits = merge([
    for scope, project_id in var.project_ids : {
      for role in var.global_runner_roles : "${scope}:${role}" => {
        project_id = project_id
        role       = role
      }
    }
  ]...)
}
