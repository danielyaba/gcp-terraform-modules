# locals {
#   _repository_data = { for k, v in var.repositories: k => value }
# }

data "github_actions_public_key" "repository_public_key" {
  repository = github_repository.repository.name
  depends_on = [ github_repository.repository ]
}

/******************************************
	      Repository configuration
 *****************************************/
resource "github_repository" "repository" {
  name        = var.repository_name
  description = "terraform-manageed github repository, maintained by ${var.owners_team}"
  visibility  = "private"
  auto_init   = true
  has_issues  = true
}

/******************************************
	        Secrets configuration
 *****************************************/
resource "github_actions_secret" "secret_authentication_provider" {
  repository       = github_repository.repository.name
  secret_name      = "GOOGLE_OAUTH_PROVIDER"
  encrypted_value  = base64encode("projects/${data.google_project.project_number.number}/locations/global/workloadIdentityPools/github-pool/providers/github-provider")
}

resource "github_actions_secret" "secret_service_account" {
  repository       = github_repository.repository.name
  secret_name      = "GOOGLE_SA"
  encrypted_value  = base64encode(google_service_account.service_account.email)
}

/******************************************
	  Environment Variables configuration
 *****************************************/
resource "github_actions_variable" "variable_gcp_location" {
  repository       = github_repository.repository.name
  variable_name    = "LOCATION"
  value            = var.location
}

resource "github_actions_variable" "variable_gcp_artifact" {
  repository       = github_repository.repository.name
  variable_name    = "GCP_ARTIFACT"
  value            = "${var.location}-docker.pkg.dev/${var.project_id}/${var.repository_name}/"
}


/******************************************
	    Templates files configuration
 *****************************************/
resource "github_repository_file" "file" {
  for_each            = fileset("${path.module}/templates/${var.framework}", "**")
  content             = file("${path.module}/templates/${var.framework}/${each.value}")
  file                = each.value
  repository          = github_repository.repository.name
  branch              = "main"
  commit_message      = "Managed by Terraform"
  commit_author       = "GCP DevOps Team"
  commit_email        = "gcpdevops@digital.gov.il"
  overwrite_on_create = true
}