
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

variable "annotations" {
  description = "Annotations that may be set by external tools to store and arbitrary metadata. They are not queryable and should be preserved when modifying objects."
  type = map(any)
}

variable "containers" {
  description = "Containers in arbitrary key => attributes format."
  type = map(object({
    image   = string
    args    = optional(list(string))
    command = optional(list(string))
    env     = optional(map(string), {})
    env_from_key = optional(map(object({
      key  = string
      name = string
    })), {})
    liveness_probe = optional(object({
      action = object({
        grpc = optional(object({
          port    = optional(number)
          service = optional(string)
        }))
        http_get = optional(object({
          http_headers = optional(map(string), {})
          path         = optional(string)
        }))
      })
      failure_threshold     = optional(number)
      initial_delay_seconds = optional(number)
      period_seconds        = optional(number)
      timeout_seconds       = optional(number)
    }))
    ports = optional(map(object({
      container_port = optional(number)
      name           = optional(string)
      protocol       = optional(string)
    })), {})
    resources = optional(object({
      limits = optional(object({
        cpu    = string
        memory = string
      }))
      requests = optional(object({
        cpu    = string
        memory = string
      }))
    }))
    startup_probe = optional(object({
      action = object({
        grpc = optional(object({
          port    = optional(number)
          service = optional(string)
        }))
        http_get = optional(object({
          http_headers = optional(map(string), {})
          path         = optional(string)
        }))
        tcp_socket = optional(object({
          port = optional(number)
        }))
      })
      failure_threshold     = optional(number)
      initial_delay_seconds = optional(number)
      period_seconds        = optional(number)
      timeout_seconds       = optional(number)
    }))
    volume_mounts = optional(map(string), {})
  }))
  default  = {}
  nullable = false
}

variable "encryption_key" {
  description = "A reference to a customer managed encryption key (CMEK) to use to encrypt this container image."
  type = string
  default = null
}

variable "eventarc_triggers" {
  description = "Event arc triggers for different sources."
  type = object({
    audit_log = optional(map(object({
      method  = string
      service = string
    })), {})
    pubsub                 = optional(map(string), {})
    service_account_email  = optional(string)
    service_account_create = optional(bool, false)
  })
  default = {}
  validation {
    condition = (
      var.eventarc_triggers.service_account_email == null && length(var.eventarc_triggers.audit_log) == 0
      ) || (
      var.eventarc_triggers.service_account_email != null
    )
    error_message = "service_account_email is required if providing audit_log"
  }
}

variable "execution_environment" {
  description = "The execution environment being used to host this Task. Possible values are: EXECUTION_ENVIRONMENT_GEN1, EXECUTION_ENVIRONMENT_GEN2."
  type = string
  default = null
}

variable "labels" {
  description = "Resource labels."
  type        = map(string)
  default     = {}
}

variable "max_retries" {
  description = "Number of retries allowed per Task, before marking this Task failed."
  type = number
}

variable "name" {
  description = "Name used for cloud run service."
  type        = string
}

variable "parallelism" {
  description = "Maximum desired number of tasks the execution should run at given time."
  type = number
  default = null
}

variable "prefix" {
  description = "Optional prefix used for resource names."
  type        = string
  default     = null
  validation {
    condition     = var.prefix != ""
    error_message = "Prefix cannot be empty, please use null instead."
  }
}

variable "project_id" {
  description = "Project id used for all resources."
  type        = string
}

variable "region" {
  description = "Region used for all resources."
  type        = string
  default     = "europe-west1"
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

variable "task_count" {
  description = "Number of tasks the execution should run."
  type = number
  default = null
}

variable "timeout" {
  description = "Maximum duration the instance is allowed for responding to a request."
  type        = string
  default     = null
}

variable "volumes" {
  description = "Named volumes in containers in name => attributes format."
  type = map(object({
    secret_name  = string
    sql_instance_create = optional(bool, false)
    sql_instances = optional(string)
    default_mode = optional(string)
    items = optional(map(object({
      path = string
      mode = optional(string)
    })))
  }))
  default  = {}
  nullable = false
}

variable "vpc_access" {
  description = "VPC Access configuration to use for this Task."
  type = object({
    connector = optional(string)
    egress = optional(string)
    network_interfaces = optional(object({
      network = optional(string)
      subnetwork = optional(string)
      tags = optional(list(string))
    }))
  })
  default = {}
  nullable = false
}

variable "vpc_connector_create" {
  description = "Populate this to create a VPC connector. You can then refer to it in the template annotations."
  type = object({
    ip_cidr_range = optional(string)
    vpc_self_link = optional(string)
    machine_type  = optional(string)
    name          = optional(string)
    instances = optional(object({
      max = optional(number)
      min = optional(number)
    }), {})
    throughput = optional(object({
      max = optional(number)
      min = optional(number)
    }), {})
    subnet = optional(object({
      name       = optional(string)
      project_id = optional(string)
    }), {})
  })
  default = null
}

variable "scheduler" {
  type = object({
    name = string
    description = optional(string)
    schedule = optional(string)
    time_zone = optional(string)
    passued = optional(string)
    attempt_deadline = optional(string)
    retry_config = optional(object({
      min_backoff_duration = string
      max_retry_duration = string
      max_doublings = string
      retry_count = string
    }))
    pubsub_target = optional(object({
      topic_name = string
      data = string
      attributes = map(any)
    }))
    app_engine_http_target = optional(object({
      http_method = string
      app_engine_routing = optional(object({
        service = string
        version = string
        instance = string
      }))
      relative_uri = string
      body = string
      headers = map(any)
    }))
    http_target = optional(object({
      uri = string
      http_method = string
      body = string
      headers = map(any)
      outh_token = optional(object({
        service_account_email = string
        scope = optional(string)
      }))
      oidc_token = optional(object({
        service_account_email = string
        audience = optional(string)
      }))
    }))
  })
  default = null
}