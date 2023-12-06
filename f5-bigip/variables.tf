variable "prefix" {
  description = "Prefix for resources created by this module"
}

variable "vm_name" {
  type        = string
  description = "Name of F5 BIGIP VM to be used, default is empty string meaning module adds with prefix + random_id"
  default     = ""
}

variable "project_id" {
  type        = string
  description = "The GCP project identifier where the cluster will be created."
}

variable "region" {
  type        = string
  description = "The compute zones which will host the BIG-IP VMs"
  default     = "me-west1"
}

variable "min_cpu_platform" {
  type        = string
  description = "Minimum CPU platform for the VM instance such as Intel Haswell or Intel Skylake"
  default     = "Intel Cascade Lake"
}

variable "machine_type" {
  type        = string
  description = "The machine type to create,if you want to update this value (resize the VM) after initial creation, you must set allow_stopping_for_update to true"
  default     = "n2-standard-8"
}

variable "automatic_restart" {
  type        = bool
  description = "Specifies if the instance should be restarted if it was terminated by Compute Engine (not a user),defaults to true."
  default     = true
}

variable "preemptible" {
  type        = string
  description = "Specifies if the instance is preemptible. If this field is set to true, then automatic_restart must be set to false,defaults to false."
  default     = false
}

variable "image" {
  type        = string
  description = "This can be one of: the image's self_link, projects/{project}/global/images/{image}, projects/{project}/global/images/family/{family}, global/images/{image}, global/images/family/{family}, family/{family}, {project}/{family}, {project}/{image}, {family}, or {image}."
  default     = "projects/f5-7626-networks-public/global/images/f5-bigip-16-1-4-1-0-53-5-byol-all-modules-1boot-loc-1026112549"
}

variable "disk_type" {
  type        = string
  description = "The GCE disk type. May be set to pd-standard, pd-balanced or pd-ssd."
  default     = "pd-ssd"
}

variable "disk_size_gb" {
  type        = number
  description = " The size of the image in gigabytes. If not specified, it will inherit the size of its base image."
  default     = 100
}

variable "f5_username" {
  description = "The admin username of the F5 Bigip that will be deployed"
  default     = "admin"
}

variable "f5_password" {
  description = "The admin password of the F5 Bigip that will be deployed"
  default     = "Default123456!"
}

variable "dns_server" {
  type        = string
  description = "DNS server to configure in startup-script"
  default     = "169.254.169.254"
}

variable "ntp_server" {
  type        = string
  description = "NTP server to configure in startup-script"
  default     = "0.us.pool.ntp.org"
}

variable "timezone" {
  type        = string
  description = "Timezone to configure in startup-script"
  default     = "UTC"
}

variable "dedicated_instances_configs" {
  description = "The F5 VMs configuration. The map keys are the zones where the VMs are deployed."
  type = map(object({
    license_key = optional(string, "AAAAA-BBBBB-CCCCC-DDDDD-EEEEEEE")
  }))
}

variable "shared_instances_configs" {
  description = "The F5 VMs shared configurations."
  type = object({
    labels          = optional(map(string))
    tags            = optional(list(string))
    service_account = string
    ilb_vip         = string
    dns_suffix      = string
  })
}

variable "vpc_config" {
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

variable "tags" {
  type        = list(string)
  description = "defualt tags for f5-bigip-vms"
  default     = ["appliance-waf", "allow-web"]
}

