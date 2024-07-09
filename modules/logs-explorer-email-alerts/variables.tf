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

variable "email_alerts" {
  description = "Email alerts."
  type = map(object({
    description = optional(string, "Terraform managed.")
    log_filter  = string
    environment_variables = object({
      DISCLAIMER  = string
      EMAIL_FROM  = string
      EMAIL_TO    = string
      SMTP_PORT   = optional(string)
      SMTP_SERVER = optional(string, "smtp.dgt.gcp.internal")
      SUBJECT     = string
    })
  }))
}

variable "folder_id" {
  description = "Folder id in format folders/[FOLDER_ID] ."
  type        = string
}

variable "function_config" {
  description = "Cloud function configuration. Defaults to using main as entrypoint, 1 instance with 256MiB of memory, and 180 second timeout."
  type = object({
    entry_point     = optional(string, "get_topic_message")
    instance_count  = optional(number, 1)
    memory_mb       = optional(number, 256) # Memory in MB
    cpu             = optional(string, "0.166")
    runtime         = optional(string, "python310")
    timeout_seconds = optional(number, 180)
  })
  default = {
    entry_point     = "get_topic_message"
    instance_count  = 1
    memory_mb       = 256
    cpu             = "0.166"
    runtime         = "python310"
    timeout_seconds = 180
  }
}

# variable "ingress_settings" {
#   description = "Control traffic that reaches the cloud function. Allowed values are ALLOW_ALL, ALLOW_INTERNAL_AND_GCLB and ALLOW_INTERNAL_ONLY ."
#   type        = string
#   default     = "ALLOW_INTERNAL_ONLY"
# }

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

# variable "trigger_config" {
#   description = "Function trigger configuration."
#   type = object({
#     event_type   = string
#     retry_policy = string
#   })
#   default = {
#     event_type   = "google.cloud.pubsub.topic.v1.messagePublished"
#     retry_policy = "RETRY_POLICY_DO_NOT_RETRY"
#   }
# }

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
