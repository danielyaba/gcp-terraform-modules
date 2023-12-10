output "f5-bigip-vms" {
  value = { for k, v in resource.google_compute_instance.f5-bigip-vms : v.name => {
    mgmtPort      = "443"
    mgmtPrivateIP = v.network_interface[1].network_ip
    externalIP    = v.network_interface[0].network_ip
    internalIP    = v.network_interface[2].network_ip
    self_link     = v.self_link
    id            = v.id
    zone          = v.zone
  } }
  description = "Details of every f5-bigip instance."
}

output "shared_instances_configs" {
  value = {
    service_account = var.shared_instances_configs.service_account
    username        = "Username as provided in startup-script"
    password        = "Password as provided in startup-script"
    dns_suffix      = var.shared_instances_configs.dns_suffix
  }
  description = "Details of shared instances config."
}