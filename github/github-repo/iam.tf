data "google_project" "project_number" {
  project_id = var.project_id
}


/******************************************
	      Service-accounts configuration
 *****************************************/
resource "google_service_account" "service_account" {
  project                   = var.project_id
  account_id                = "cicd-sa-github_${var.repository_name}"
  display_name              = "cicd-sa-github_${var.repository_name}"
  description               = "terraform-manageed service account for github repository ${var.repository_name}"
}

/******************************************
	      IAM binding configuration
 *****************************************/
resource "google_service_account_iam_binding" "iam_binding" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${google_service_account.service_account.email}"
  role               = "roles/iam.workloadIdentityUser"
  members            = [
      "principalSet://iam.googleapis.com/projects/${data.google_project.project_number.number}/locations/global/workloadIdentityPools/github-pool/attribute.repository/${var.repository_name}"
  ]
}

/******************************************
	      IAM permissions configuration
 *****************************************/
data "google_iam_policy" "push_policy" {
  binding {
    role    = "roles/artifactregistry.writer"
    members = [
      "serviceAccount:${google_service_account.service_account.email}",
    ]
  }
}

resource "google_artifact_registry_repository_iam_policy" "artifact_policy" {
  project = var.project_id
  location = var.location
  repository = var.repository_name
  policy_data = data.google_iam_policy.push_policy.policy_data
}


#######################################################################################

# CREATE SERVCE-ACCOUNT
# module "service_accounts" {
#   source        = "terraform-google-modules/service-accounts/google"
#   version       = "~> 3.0"
#   project_id    = var.project_id
#   prefix        = "cicd-sa-github_"
#   names         = ["${var.repository_name}"]
# }


# CRREATE IAM BINDING FOR WORKLOAD FEDERATION
# module "projects_iam_bindings" {
#   source  = "terraform-google-modules/iam/google//modules/projects_iam"
#   version = "~> 7.6"

#   projects = ["${var.project_id}"]

#   bindings = {
#     "roles/iam.workloadIdentityUser" = [
#       "principalSet://iam.googleapis.com/projects/${data.google_project.project_number.number}/locations/global/workloadIdentityPools/github-pool/attribute.repository/${var.repository_name}",
#     ]
#   }
# }