variable "dedicated_instances_configs" {
  description = "The F5 VMs configuration. The map keys are the zones where the VMs are deployed."
  type = map(object({
    license_key = optional(string, "AAAAA-BBBBB-CCCCC-DDDDD-EEEEEEE")
    network_config = optional(object({
      external_address   = optional(string)
      internal_address   = optional(string)
      management_address = optional(string)
    }), {})
  }))
}

variable "prefix" {
  type        = string
  description = "The prefix name used for resources."
}

variable "project_id" {
  type        = string
  description = "The GCP project identifier where the cluster will be created."
}

variable "region" {
  type        = string
  description = "The compute zones which will host the BIG-IP VMs."
  # default     = "me-west1"
}

variable "shared_instances_configs" {
  description = "The F5 VMs shared configurations."
  type = object({
    f5_packages_bucket = string
    boot_disk = optional(object({
      image = optional(string, "projects/f5-7626-networks-public/global/images/f5-bigip-16-1-4-1-0-53-5-byol-all-modules-1boot-loc-1026112549")
      size  = optional(number, 100)
      type  = optional(string, "pd-ssd")
    }), {})
    dns_server         = optional(string, "169.254.169.254")
    dns_suffix         = string
    ilb_vip            = string
    labels             = optional(map(string))
    machine_type       = optional(string, "n2-standard-8")
    min_cpu_platform   = optional(string, "Intel Cascade Lake")
    ntp_server         = optional(string, "0.us.pool.ntp.org")
    password           = optional(string, "Default123456!")
    route_to_configure = optional(string)
    service_account    = optional(string)
    ssh_public_key     = optional(string, "./data/public.key")
    tags               = optional(list(string))
    timezone           = optional(string, "UTC")
    username           = optional(string, "admin")
  })
}

variable "vpc_config" {
  description = "VPC configs for resources."
  type = object({
    external = object({
      subnetwork = string
    })
    internal = object({
      subnetwork = string
    })
    management = object({
      subnetwork = string
    })
  })
}