/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


variable "build_service_account" {
  description = "Build service account email."
  type        = string
  default     = null
}

variable "environment_variables" {
  description = "Cloud function environment variables."
  type        = object({
    EMAIL_FROM    = string
    EMAIL_TO      = string
    FOLDER_NUMBER = string
    SMTP_PORT     = optional(string)
    SMTP_SERVER   = optional(string, "smtp.dgt.gcp.internal")
    SUBJECT       = optional(string, "Alert: Unlabeled GCP Projects")
  })
}

variable "function_config" {
  description = "Cloud function configuration. Defaults to using main as entrypoint, 1 instance with 256MiB of memory, and 180 second timeout."
  type = object({
    entry_point     = optional(string, "labels_checker")
    instance_count  = optional(number, 1)
    memory_mb       = optional(number, 256) # Memory in MB
    cpu             = optional(string, "0.166")
    runtime         = optional(string, "python310")
    timeout_seconds = optional(number, 180)
  })
  default = {
    entry_point     = "labels_checker"
    instance_count  = 1
    memory_mb       = 256
    cpu             = "0.166"
    runtime         = "python310"
    timeout_seconds = 180
  }
}

variable "function_scheduler" {
  description = "Cloud function scheduler resource"
  type        = object({
    name      = string
    schedule  = string
    region    = string
    time_zone = string
  })
  default = {
    name      = "labels-checker-job"
    schedule  = "0 7 * * 0"
    region    = "europe-west3"
    time_zone = "Asia/Jerusalem"
  }
}

variable "labels" {
  description = "Resource labels."
  type        = map(string)
  default     = {}
}

variable "project_id" {
  description = "Project id used for all resources."
  type        = string
}

variable "region" {
  description = "Region used for all resources."
  type        = string
  default     = "me-west1"
}

variable "service_account" {
  description = "Service account email. Unused if service account is auto-created."
  type        = string
  default     = null
}

variable "service_account_create" {
  description = "Auto-create service account."
  type        = bool
  default     = false
}

variable "vpc_connector" {
  description = "VPC connector configuration. Set create to 'true' if a new connector needs to be created."
  type = object({
    create          = optional(bool, true)
    name            = optional(string, "vpc-connector")
    egress_settings = optional(string, "ALL_TRAFFIC")
  })
}

variable "vpc_connector_config" {
  description = "VPC connector network configuration. Must be provided if new VPC connector is being created."
  type = object({
    subnetwork     = string
    min_instances  = optional(number, 2)
    max_instances  = optional(number, 10)
    machine_type   = optional(string, "e2-micro")
    max_throughput = optional(number, 1000)
  })
}