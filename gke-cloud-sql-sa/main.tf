module "service_accounts" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "~> 3.0"
  project_id = var.project_id
  names      = [var.gke_namespace]
  project_roles = [
    "${var.project_id}=>roles/cloudsql.client",
    "${var.project_id}=>roles/iam.workloadIdentityUser",
  ]
}


module "service_account-iam-bindings" {
  source = "terraform-google-modules/iam/google//modules/service_accounts_iam"

  service_accounts = [module.service_accounts.email]
  project          = var.project_id
  mode             = "adaptive"
  bindings = {
    "roles/iam.workloadIdentityUser" = [
      "serviceAccount:${var.project_id}.svc.id.goog[${var.gke_namespace}/${var.gke_namespace}]",
    ]
  }
}
