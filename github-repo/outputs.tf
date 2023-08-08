locals {
  repository_details = {
    repository_name       = github_repository.repository.full_name
    repository_url        = github_repository.repository.html_url
    service_account_email = google_service_account.service_account.email
  }
}

output repository_details {
  value = local.repository_details
}