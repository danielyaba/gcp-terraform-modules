# IP address for external nic for every f5-bigip
resource "google_compute_address" "external" {
  for_each     = var.dedicated_instances_configs
  provider     = google-beta
  project      = var.project_id
  name         = "${var.prefix}-ext-${each.key}"
  description  = "Terraform Managed"
  address_type = "INTERNAL"
  region       = var.region
  subnetwork   = var.vpc_config.external.subnetwork
}

# IP address for internal nic for every f5-bigip
resource "google_compute_address" "internal" {
  for_each     = var.dedicated_instances_configs
  provider     = google-beta
  project      = var.project_id
  name         = "${var.prefix}-int-${each.key}"
  description  = "Terraform Managed"
  address_type = "INTERNAL"
  region       = var.region
  subnetwork   = var.vpc_config.internal.subnetwork
}

# IP address for management nic for every f5-bigip
resource "google_compute_address" "management" {
  for_each     = var.dedicated_instances_configs
  provider     = google-beta
  project      = var.project_id
  name         = "${var.prefix}-mgmt-${each.key}"
  description  = "Terraform Managed"
  address_type = "INTERNAL"
  region       = var.region
  subnetwork   = var.vpc_config.management.subnetwork
}