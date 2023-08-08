variable "project_id" {
  type = string
  description = "GCP Project ID (required)"
}

variable location {
  type = string
  description = "GCP location of Artifact Registry"
  default = "me-west1"
}

variable "repository_name" {
  type = string
  description = "The name of the github repository (required)"
}

variable "framework" {
  type = string
  description = "The framework of the micro-service"
}

variable "owners_team" {
  type = string
  description = "The framework of the micro-service"
}
