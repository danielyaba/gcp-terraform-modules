resource "google_compute_address" "management" {
  for_each = toset([for k, v in var.dedicated_instances_configs : k if v.network_config.management_address == null])
  # provider     = google-beta
  project      = var.project_id
  name         = "${var.prefix}-mgmt-${each.key}"
  description  = "Terraform Managed"
  address_type = "INTERNAL"
  region       = var.region
  subnetwork   = var.vpc_config.management.subnetwork
}

resource "google_compute_address" "external" {
  for_each = toset([for k, v in var.dedicated_instances_configs : k if v.network_config.external_address == null])
  # provider     = google-beta
  project      = var.project_id
  name         = "${var.prefix}-ext-${each.key}"
  description  = "Terraform Managed"
  address_type = "INTERNAL"
  region       = var.region
  subnetwork   = var.vpc_config.external.subnetwork
}

resource "google_compute_address" "internal" {
  for_each = toset([for k, v in var.dedicated_instances_configs : k if v.network_config.internal_address == null])
  # provider     = google-beta
  project      = var.project_id
  name         = "${var.prefix}-int-${each.key}"
  description  = "Terraform Managed"
  address_type = "INTERNAL"
  region       = var.region
  subnetwork   = var.vpc_config.internal.subnetwork
}