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
}
