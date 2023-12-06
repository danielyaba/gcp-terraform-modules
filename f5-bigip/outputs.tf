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
}

output "shared_instances_configs" {
  value = {
    service_account = var.shared_instances_configs.service_account
    username        = var.f5_username
    password        = var.f5_password
    dns_suffix      = var.shared_instances_configs.dns_suffix
  }
}