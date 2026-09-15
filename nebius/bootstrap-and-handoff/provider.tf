provider "nebius" {
  parent_id = var.project_ids["global"]
  default_labels = {
    managed_by = "terraform"
    component  = "bootstrap"
  }
}
