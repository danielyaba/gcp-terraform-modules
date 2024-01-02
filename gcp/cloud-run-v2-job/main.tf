locals {
  prefix = var.prefix == null ? "" : "${var.prefix}-"
  service_account_email = (
    var.service_account_create
    ? (
      length(google_service_account.service_account) > 0
      ? google_service_account.service_account[0].email
      : null
    )
    : var.service_account
  )
  sql_instance = (
    var.volumes.sql_instance_create
    ? (
      length(google_sql_database_instance.instance) > 0
      ? google_sql_database_instance.instance[0].connection_name
      : null
    )
    : var.volumes.sql_instance
  )
  vpc_connector_create = var.vpc_connector_create != null
}

resource "google_cloud_run_v2_job" "default" {
  name     = var.name
  location = var.region
  provider = google-beta

  template {
    labels = var.labels
    annotations = var.annotations
    parallelism = var.parallelism
    task_count = var.task_count
    template {
      dynamic "containers" {
        for_each = var.containers
        content {
          name = var.containers.name
          image = var.containers.image
          command = var.containers.command
          args = var.containers.args

          dynamic "env" {
            for_each = containers.value.env_from_key
            content {
             name = env.key
             value_source {
               secret_key_ref {
                 secret = env.env.key
                 version = env.value.version
                }
              } 
            }
          }
          dynamic "resources" {
            for_each = containers.value.resources == null ? [] : [""]
            content {
              limits   = containers.value.resources.limits
            }
          }
          dynamic "ports" {
            for_each = containers.value.ports == null ? [] : [""]
            content {
              container_port = ports.value.container_port
              name           = ports.value.name
            }
          }

          dynamic "volume_mounts" {
            for_each = containers.value.volume_mounts
            content {
              name       = volume_mounts.key
              mount_path = volume_mounts.value
            }
          }
          working_dir = var.containers.working_dir
        }
      }

      dynamic "volumes" {
        for_each = var.volumes
        content {
          name = volumes.key
          cloud_sql_instance {
            instances = local.sql_instance
          }
          empty_dir {
            medium = volumes.empty_dir.medium
            size_limit = volumes.empty_dir.size_limit
          }
          secret {
            secret  = volumes.value.secret
            default_mode = volumes.value.default_mode
            dynamic "items" {
              for_each = volumes.value.items
              content {
                mode = items.value.mode
                path = items.value.path
                version  = items.value.version
              }
            }
          }
        }
      }
      
      dynamic "vpc_access" {
        for_each = var.vpc_connector == null ? [] : [""]
        content {
          connector = vpc_connector.value.connector
          egress = vpc_connector.value.egress
          dynamic "network_interfaces" {
            for_each = vpc_connector.value.network_interfaces
            content {
              network = network_interfaces.value.network
              subnetwork = network_interfaces.value.subnetwork
            }
          }
        }
      }

      encryption_key = var.encryption_key
      execution_environment = var.execution_environment
      max_retries = var.max_retries
      service_account = local.service_account_email
      timeout = var.timeout
    }
  }
}


resource "google_vpc_access_connector" "connector" {
  count   = local.vpc_connector_create ? 1 : 0
  project = var.project_id
  name = (
    var.vpc_connector_create.name != null
    ? var.vpc_connector_create.name
    : var.name
  )
  region         = var.region
  ip_cidr_range  = var.vpc_connector_create.ip_cidr_range
  network        = var.vpc_connector_create.vpc_self_link
  machine_type   = var.vpc_connector_create.machine_type
  max_instances  = var.vpc_connector_create.instances.max
  max_throughput = var.vpc_connector_create.throughput.max
  min_instances  = var.vpc_connector_create.instances.min
  min_throughput = var.vpc_connector_create.throughput.min
  dynamic "subnet" {
    for_each = alltrue([for k, v in var.vpc_connector_create.subnet : (v == null)]) ? [] : [""]
    content {
      name       = var.vpc_connector_create.subnet.name
      project_id = var.vpc_connector_create.subnet.project_id
    }
  }
}