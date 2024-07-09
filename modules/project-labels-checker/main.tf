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
  service_account_email = (
    var.service_account_create
    ? google_service_account.service_account[0].email
    : var.service_account
  )
}

resource "google_cloudfunctions2_function" "function" {
  provider    = google-beta
  project     = var.project_id
  location    = var.region
  name        = "labels-checker-cf"
  description = "Labels-Checker Cloud Function - Terraform-managed"
  labels      = var.labels
  build_config {
    entry_point           = var.function_config.entry_point
    environment_variables = var.environment_variables
    runtime               = var.function_config.runtime
    service_account       = var.build_service_account
    source {
      storage_source {
        bucket = google_storage_bucket.bucket.name
        object = google_storage_bucket_object.bundle.name
      }
    }
  }
  service_config {
    available_cpu         = var.function_config.cpu
    available_memory      = "${var.function_config.memory_mb}M"
    environment_variables = var.environment_variables
    ingress_settings      = "ALLOW_INTERNAL_ONLY"
    max_instance_count    = var.function_config.instance_count
    service_account_email = local.service_account_email
    timeout_seconds       = var.function_config.timeout_seconds
    vpc_connector         = local.vpc_connector
    vpc_connector_egress_settings = try(
    var.vpc_connector.egress_settings, null)
  }
}

resource "google_cloud_scheduler_job" "job" {
  project   = var.project_id
  name      = var.function_scheduler.name
  schedule  = var.function_scheduler.schedule
  region    = var.function_scheduler.region
  time_zone = var.function_scheduler.time_zone
  http_target {
    http_method = "POST"
    uri         = google_cloudfunctions2_function.function.url

    oidc_token {
      service_account_email = local.service_account_email
    }
  }
}

resource "google_cloud_run_service_iam_member" "invoker" {
  # cloud run resources are needed for invoker role to the underlying service
  project  = var.project_id
  location = google_cloudfunctions2_function.function.location
  service  = google_cloudfunctions2_function.function.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${local.service_account_email}"
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
  name                        = "labels-checker-cf-gcs"
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
  output_path      = "/tmp/bundle-labels-checker.zip"
  output_file_mode = "0644"
}

resource "google_service_account" "service_account" {
  count        = var.service_account_create ? 1 : 0
  project      = var.project_id
  account_id   = "labels-checker-cf-sa"
  display_name = "labels-checker-cf-sa"
  description  = "Service Account for Labels-Checker Cloud-Functions"
}

resource "google_folder_iam_member" "folder" {
  folder  = "folders/${var.environment_variables.FOLDER_NUMBER}"
  role    = "roles/browser"
  member  = "serviceAccount:${local.service_account_email}"
}



