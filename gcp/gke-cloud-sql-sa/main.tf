resource "google_service_account" "service_account" {
  project = var.project_id
  account_id   = var.gke_namespace
  display_name = var.gke_namespace
}

resource "google_project_iam_binding" "project" {
  for_each = toset(var.sa_roles)
  project = var.project_id
  role    = each.value

  members = [
    "serviceAccount:${google_service_account.service_account.email}",
  ]
}

resource "google_service_account_iam_binding" "service-account-iam" {
  service_account_id = google_service_account.service_account.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${var.project_id}.svc.id.goog[${var.gke_namespace}/${var.gke_namespace}]",
  ]
}

# module "service_accounts" {
#   source     = "terraform-google-modules/service-accounts/google"
#   version    = "~> 3.0"
#   project_id = var.project_id
#   names      = [var.gke_namespace]
#   project_roles = [
#     "${var.project_id}=>roles/cloudsql.client",
#     "${var.project_id}=>roles/iam.workloadIdentityUser",
#   ]
# }

# module "service_account-iam-bindings" {
#   source = "terraform-google-modules/iam/google//modules/service_accounts_iam"

#   service_accounts = [module.service_accounts.email]
#   project          = var.project_id
#   mode             = "adaptive"
#   bindings = {
#     "roles/iam.workloadIdentityUser" = [
#       "serviceAccount:${var.project_id}.svc.id.goog[${var.gke_namespace}/${var.gke_namespace}]",
#     ]
#   }
# }
