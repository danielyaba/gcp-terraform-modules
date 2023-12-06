
locals {
  _f5_urls = {
    as3 = "https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.46.0/f5-appsvcs-3.46.0-5.noarch.rpm"
    cfe = "https://github.com/F5Networks/f5-cloud-failover-extension/releases/download/v1.15.0/f5-cloud-failover-1.15.0-0.noarch.rpm"
    do   = "gs://${module.f5-packages-gcs.name}/f5-declarative-onboarding/v1.41.0/f5-declarative-onboarding-1.41.0-8.noarch.rpm"
    # do   = "http://${resource.google_compute_instance.f5-packages-nginx.network_interface.0.network_ip}/5-declarative-onboarding/v1.41.0/f5-declarative-onboarding-1.41.0-8.noarch.rpm"
    fast = "https://github.com/F5Networks/f5-appsvcs-templates/releases/download/v1.25.0/f5-appsvcs-templates-1.25.0-1.noarch.rpm"
    init = "https://cdn.f5.com/product/cloudsolutions/f5-bigip-runtime-init/v1.6.2/dist/f5-bigip-runtime-init-1.6.2-1.gz.run"
    ts   = "https://github.com/F5Networks/f5-telemetry-streaming/releases/download/v1.33.0/f5-telemetry-1.33.0-1.noarch.rpm"
  }
  _f5_urls_split = {
    for k, v in local._f5_urls
    : k => split("/", v)
  }
  _f5_vers = {
    as3  = split("-", local._f5_urls_split.as3[length(local._f5_urls_split.as3) - 1])[2]
    cfe  = split("-", local._f5_urls_split.cfe[length(local._f5_urls_split.cfe) - 1])[3]
    do   = split("-", local._f5_urls_split.do[length(local._f5_urls_split.do) - 1])[3]
    fast = format("v%s", split("-", local._f5_urls_split.fast[length(local._f5_urls_split.fast) - 1])[3])
    ts   = format("v%s", split("-", local._f5_urls_split.ts[length(local._f5_urls_split.ts) - 1])[2])
  }
  f5_config = merge(
    { NIC_COUNT = true },
    { for k, v in local._f5_urls : upper("${k}_url") => v },
    { for k, v in local._f5_vers : upper("${k}_ver") => v },
    # hostnames and management IP addresses for the cluster configuration
    { for k, v in var.dedicated_instances_configs : "hostname_${k}" => "${var.prefix}-${k}.${var.shared_instances_configs.dns_suffix}" },
    { for k, v in var.dedicated_instances_configs : "mgmt_ip_${k}" => resource.google_compute_address.management[k].address }
  )
}

resource "google_compute_instance" "f5-bigip-vms" {
  for_each = var.dedicated_instances_configs
  name     = "${var.prefix}-${each.key}"
  zone     = "${var.region}-${each.key}"
  project  = var.project_id
  # Scheduling options
  min_cpu_platform = var.min_cpu_platform
  machine_type     = var.machine_type
  scheduling {
    automatic_restart = var.automatic_restart
    preemptible       = var.preemptible
  }
  boot_disk {
    auto_delete = true
    initialize_params {
      type  = var.disk_type
      size  = var.disk_size_gb
      image = var.image
    }
  }
  service_account {
    email  = var.shared_instances_configs.service_account
    scopes = ["cloud-platform"]
  }
  can_ip_forward = true

  # External Nic
  network_interface {
    subnetwork = var.vpc_config.external.subnetwork
    network_ip = resource.google_compute_address.external[each.key].address
  }

  # Management Nic
  network_interface {
    subnetwork = var.vpc_config.management.subnetwork
    network_ip = resource.google_compute_address.management[each.key].address
  }

  # Internal NIC
  network_interface {
    subnetwork = var.vpc_config.internal.subnetwork
    network_ip = resource.google_compute_address.internal[each.key].address
  }

  metadata_startup_script = replace(templatefile("${path.module}/data/f5_onboard_gcs_mgmt.tmpl",
    merge(local.f5_config, {
      onboard_log                       = "/var/log/startup-script.log",
      libs_dir                          = "/config/cloud/gcp/node_modules",
      f5_username                       = var.f5_username
      f5_password                       = var.f5_password
      gcp_secret_manager_authentication = false
      gcp_secret_name                   = ""
      ssh_keypair                       = file("${path.module}/data/public.key")
      license_key                       = each.value.license_key
      dns_suffix                        = var.shared_instances_configs.dns_suffix
      dns_server                        = var.dns_server
      ntp_server                        = var.ntp_server
      timezone                          = var.timezone
      # hostname1                         = "${var.prefix}-a.${var.shared_instances_configs.dns_suffix}"
      # hostname2                         = "${var.prefix}-b.${var.shared_instances_configs.dns_suffix}"
      # mgmt_ip_a                         = resource.google_compute_address.management["a"].address
      # mgmt_ip_b                         = resource.google_compute_address.management["b"].address
      mgmt_ip = resource.google_compute_address.management[each.key].address
      # self_ip_a                         = resource.google_compute_address.internal["a"].address
      # self_ip_b                         = resource.google_compute_address.internal["b"].address
      ilb_vip          = var.shared_instances_configs.ilb_vip
      private_vip      = resource.google_compute_address.external[each.key].address
      internal_subnets = "100.64.0.0/10"
      }
  )), "/\r/", "")

  labels = var.shared_instances_configs.labels
  tags   = try(concat(var.shared_instances_configs.tags, var.tags), var.tags)

  depends_on = [
    google_compute_address.external,
    google_compute_address.internal,
    google_compute_address.management,
  ]
}