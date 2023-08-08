# Terraform Github Repository Module
This module creates a service account in GCP with OIDC authentication for accessing GCP Cloul SQL. The resource/services/activations/deletions that this module will create are:
* Create a Service Account in GCP with permissions for Workload Indentity authentication and access to GCP Cloud SQL 


## Usage

Basic usage of this module is as follows:

```hcl
module "gke-cloud-sql-sa" {
  source        = "github.com/danielyaba/terraform-gcp-modules"
  project_id    = "<PROJECT_ID>"
  gke_namespace = "<GKE_NAMESPACE>"
}
```

Then perform the following commands on the root folder:

* ```terraform init``` to get the plugins
* ```terraform plan``` to see the infrastructure plan
* ```terraform appky ``` to apply the infrastructure build
* ```terraform destroy ``` to destroy the built infrastructure

## Inputs
| Name | Description | Type | Defualt | Required |
| :--- | :--- | :--- | :--- | :--- |
| project_id | GCP project with nessacery configuration | string | n/a | yes |
| k8s_namespace | Namespace in GKE cluster to create service account  | string | n/a | yes |

## Outputs
| Name | Description |
| :--- | :--- |
<!-- TODO: Add outputs to module -->

## Requirements
Before this module can be used on a project, you must ensure that the following pre-requisites are fulfilled:
<!-- TODO: Add requirements to module -->



