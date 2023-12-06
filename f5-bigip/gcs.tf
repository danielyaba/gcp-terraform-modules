# module "f5-packages-gcs" {
#   source        = "./modules/gcs"
#   name          = "f5-packages-gcs"
#   project_id    = var.project_ids.office
#   location      = upper(var.region)
#   storage_class = "STANDARD"
#   force_destroy = true
#   iam = {
#     "roles/storage.objectUser" = ["serviceAccount:${var.service_accounts.waf_sa}"]
#   }
#   labels = {
#     owner = "gcpsecops"
#     env   = "prod"
#   }
# }

# create bucket for f5-declerative-onboarding rpm
resource google_storage_bucket "f5-packges-gcs" {
  project = var.project_id
  name = "dgt-gcp-${split(".", var.shared_instances_configs.dns_suffix)[0]}-f5-packages-gcs"
  location      = upper(var.region)
  storage_class = "STANDARD"
  force_destroy = true
}

# assign iam permission to office-waf service-account
resource "google_storage_bucket_iam_binding" "binding" {
  bucket = google_storage_bucket.f5-packges-gcs.name
  role = "roles/storage.objectUser"
  members = [
    "serviceAccount:${var.shared_instances_configs.service_account}",
  ]
}

# upload RPM package
resource google_storage_bucket_object "f5-do-rpm" {
  bucket = module.f5-packages-gcs.name
  name = "f5-declarative-onboarding/v1.41.0/f5-declarative-onboarding-1.41.0-8.noarch.rpm"
  content = filebase64("${path.module}/data/f5-declarative-onboarding-1.41.0-8.noarch.rpm")
}