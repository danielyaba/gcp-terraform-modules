variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "gke_namespace" {
  type        = string
  description = "Namespace of k8s service with also be collerate with service account"
}

