locals {
  vpc_connector = (
    var.vpc_connector == null
    ? null
    : (
      try(var.vpc_connector.create, false) == false
      ? var.vpc_connector.name
      : google_vpc_access_connector.connector[0].id
    )
  )
}

resource "google_cloudfunctions2_function" "function" {
  for_each    = var.email_alerts
  provider    = google-beta
  project     = var.project_id
  location    = var.region
  name        = "${each.key}-cf"
  description = "${each.value.description} - Terraform-managed"
  labels      = var.labels
  build_config {
    entry_point           = var.function_config.entry_point
    environment_variables = each.value.environment_variables
    runtime               = var.function_config.runtime
    service_account       = var.build_service_account
    source {
      storage_source {
        bucket = google_storage_bucket.bucket.name
        object = google_storage_bucket_object.bundle.name
      }
    }
  }
  event_trigger {
    event_type            = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic          = google_pubsub_topic.topic.id
    retry_policy          = "RETRY_POLICY_DO_NOT_RETRY"
    service_account_email = google_service_account.service_account.email
    trigger_region        = var.region
  }
  service_config {
    available_cpu         = var.function_config.cpu
    available_memory      = "${var.function_config.memory_mb}M"
    environment_variables = each.value.environment_variables
    ingress_settings      = "ALLOW_INTERNAL_ONLY"
    max_instance_count    = var.function_config.instance_count
    service_account_email = google_service_account.service_account.email
    timeout_seconds       = var.function_config.timeout_seconds
    vpc_connector         = local.vpc_connector
    vpc_connector_egress_settings = try(
    var.vpc_connector.egress_settings, null)
  }
}

resource "google_cloud_run_service_iam_member" "invoker" {
  # cloud run resources are needed for invoker role to the underlying service
  for_each = var.email_alerts
  project  = var.project_id
  location = google_cloudfunctions2_function.function[each.key].location
  service  = google_cloudfunctions2_function.function[each.key].name
  role     = "roles/run.invoker"
  member   = google_service_account.service_account.member
}

resource "google_vpc_access_connector" "connector" {
  count   = try(var.vpc_connector.create, false) == true ? 1 : 0
  project = var.project_id
  name    = var.vpc_connector.name
  region  = var.region
  subnet {
    name       = split("/", var.vpc_connector_config.subnetwork)[length(split("/", var.vpc_connector_config.subnetwork)) - 1]
    project_id = split("/", var.vpc_connector_config.subnetwork)[1]
  }
  machine_type   = var.vpc_connector_config.machine_type
  min_instances  = var.vpc_connector_config.min_instances
  max_instances  = var.vpc_connector_config.max_instances
  max_throughput = var.vpc_connector_config.max_throughput
}

resource "google_storage_bucket" "bucket" {
  project                     = var.project_id
  name                        = "alert-notify-cf-gcs"
  uniform_bucket_level_access = true
  location                    = var.region
}

resource "google_storage_bucket_object" "bundle" {
  name   = "bundle-${data.archive_file.bundle.output_md5}.zip"
  bucket = google_storage_bucket.bucket.name
  source = data.archive_file.bundle.output_path
}

data "archive_file" "bundle" {
  type             = "zip"
  source_dir       = "${path.module}/function/"
  output_path      = "/tmp/bundle-alert-notify.zip"
  output_file_mode = "0644"
}

resource "google_logging_folder_sink" "sink" {
  for_each         = var.email_alerts
  name             = each.key
  description      = "Log sink for ${each.key} - Terraform managed."
  folder           = var.folder_id
  destination      = "pubsub.googleapis.com/${google_pubsub_topic.topic.id}"
  filter           = each.value.log_filter
  include_children = true
}

resource "google_pubsub_topic" "topic" {
  project = var.project_id
  name    = "alert-notify-topic"
}

resource "google_pubsub_topic_iam_binding" "binding" {
  project = var.project_id
  topic   = google_pubsub_topic.topic.name
  role    = "roles/pubsub.publisher"
  members = [
    for k, v in google_logging_folder_sink.sink
    : google_logging_folder_sink.sink[k].writer_identity
  ]
}

resource "google_service_account" "service_account" {
  project      = var.project_id
  account_id   = "alert-notify-cf-sa"
  display_name = "alert-notify-cf-sa"
  description  = "Service Account for Alert-Notify Cloud-Functions"
}

