# Terraform Github Repository Module
This module creates a Github repository and a service account in GCP with OIDC authentication for accessing GCP Artifact Registry. The resource/services/activations/deletions that this module will create are:
* Create a Github repository with provided addons.
* Create a Service Account in GCP with permissions for Workload Indentity authentication and push to GCP Artifact Registry (service account will be created in the following format: "cicd-sa-github_<REPO-NAME>").
* Create a GCP Artifact Registry with least permissions to push CICD pipelines docker images 


## Usage

Add Github token in the root providers.tf file as follow:

```hcl
provider "github" {
  token = "<GITHUB-TOKEN>"
}
```

Basic usage of this module is as follows:

```hcl
module "github-repo" {
  source                     = "./modules/github-repo"
  project_id                 = "<PROJECT_ID>"
  repository_name            = "<GITHUB_REPOSITORY_NAME>"
  framework                  = "<FRAMEWORK>"
  owners_team                = "<OWNERS_TEAM">
}
```

Then perform the following commands on the root folder:

* ```terraform init``` to get the plugins
* ```terraform plan``` to see the infrastructure plan
* ```terraform apply ``` to apply the infrastructure build
* ```terraform destroy ``` to destroy the built infrastructure

## Inputs
| Name | Description | Type | Defualt | Required |
| :--- | :--- | :--- | :--- | :--- |
| project_id | GCP project with nessacery configuration | string | n/a | yes |
| repository_name | Repository name to create in Github | string | n/a | yes |
| location | Location for setup artifact registry | string | me-west1 | no |
| framework | Framework of the micro-service (currently supported: python, terraform) | string | n/a | yes |
| owners_team | Team who is respos  ible for this repository | string | n/a | yes |

## Outputs
| Name | Description |
| :--- | :--- |
| repository_name | Name of repository created in Github account |
| repository_url | URL link to repository |
| service_account_email | Email of the service account created in GCP for accessing token with OIDC to GCP Artifact Registry |

## Requirements
Before this module can be used on a project, you must ensure that the following pre-requisites are fulfilled:
1. Terraform are installed on the machine where Terraform is executed.
2. The service account you execute the module with, has the right permissions.
3. Personal Access Token is created and saved in Github-Action-secrets / external Secret-Manager
4. IAM workload identity pool and OIDC provider already configured in GCP prject with the names "github-pool" and "github-provider"

### Creating IAM workload identity configuration 
Create IAM workload identity provider and oidc pool using gcloud commands:
```hcl
PROJECT_ID = <PROJECT_ID>
gcloud iam workload-identity-pools create github-pool --location="global" --project $PROJECT_ID

gcloud iam workload-identity-pools providers create-oidc github-provider \
  --location="global" \
  --workload-identity-pool=github-pool  \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-mapping="attribute.actor=assertion.actor,google.subject=assertion.sub,attribute.repository=assertion.repository" \
  --project $PROJECT_ID
  ```

### Using Github token in the workflow
When Terraform is executing 'terraform plan' command it requires a token for Github
Add the token as environment variable under 'Terraform Plan' and 'Terraform Apply' steps
To do so, you should add some extra "with" values which requires terraform version
To install the lastest version of Terraform add this step in the beggining:

```hcl
- id: get_tf_latest_ver
  name: 'Get latest Terraform GitHub release and remove "v" from tag name for version'
  shell: bash
  run: echo "tf_actions_version=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | jq -r '.tag_name' | sed 's/^v//')" >> $GITHUB_OUTPUT
```

Now on 'Terraform Plan' & 'Terraform Apply' commands you should specify Terraform version with the output of the previous step

```hcl
- name: 'Terraform Plan'
  uses: hashicorp/terraform-github-actions@master
  with:
    tf_actions_version: ${{ steps.get_tf_latest_ver.outputs.tf_actions_version }}
    tf_actions_subcommand: 'plan'
    tf_actions_working_dir: '.'
    tf_actions_comment: true
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    TF_VAR_github_token: ${{ steps.secrets.outputs.token }}
  
- name: 'Terraform Apply'
  uses: hashicorp/terraform-github-actions@master
  with:
    tf_actions_version: ${{ steps.get_tf_latest_ver.outputs.tf_actions_version }}
    tf_actions_subcommand: 'apply'
    tf_actions_working_dir: '.'
    tf_actions_comment: true
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    TF_VAR_github_token: ${{ steps.secrets.outputs.token }}
```

