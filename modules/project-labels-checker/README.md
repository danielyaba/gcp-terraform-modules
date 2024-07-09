# Project-Labels-Checker Modules

This module allows creating Cloud-Function for alerting about project with non-compliance labels.  

It creates a Cloud-Function, GCS Bucket, VPC-Connector, Service-Account and Cloud-Scheduler-Job.  

## Prerequisites
1. Make sure the following API services are enabled on you project:
* cloudbuild.googleapis.com - Cloud Build API
* eventarc.googleapis.com - Eventarc API
* run.googleapis.com - Cloud Run API
* vpcaccess.googleapis.com - VPC Serverless API
* cloudscheduler.googleapis.com - Cloud Scheduler API

2. Make sure that vpc connector subnet with `/28` is exists in the VPC
3. 
4. Make sure vpc-connector has relevant FW ingress rules from serverless infrastructure in the host shared VPC project under the relevant VP
Ingress rules:
- sources IP: 35.199.224.0/19
- target tags: vpc-connector

## Examples:
Note: `environment_variables` must be in captial letters.  

### Basic example:
```
module "labels-checker" {
  source = "./modules/labels-checker"
  project_id = var.project_id
  environment_variables = {
    EMAIL_TO      = "devops-team@exmaple.com"
    EMAIL_FROM    = "security-alerts@exmaple.com"
    FOLDER_NUMBER = "" 
  }
  vpc_connector = {
    create = true
  }
  vpc_connector_config = {
    subnetwork = var.subnets.net-office-0-snet-mw1-dev-vpc-connector
  }
}
```

### VPC connector management
This module supports creation of VPC-Connector along with Cloud-Function.  
Specifying `create = true` under `vpc_connector` variable will cause the module to create the VPC-Connector with the name `vpc-connector` (default name can be overriden with `name = <VPC-CONNECTOR-NAME>`).  
>**Notes:**   
Without VPC-Connector the function will not be operational.  
If you are planning to have multiple Cloud-Functions it is recommended to create the VPC-Connector outside the module.   

Create VPC-Connector within the module:
```
module "labels-checker" {
  source = "./modules/labels-checker"
  project_id = var.project_id
  environment_variables = {
    EMAIL_TO   = "devops-team@exmaple.com"
    EMAIL_FROM = "security-alerts@exmaple.com"
  }
  vpc_connector = {
    name = "my-vpc-connector" # optional
  }
  vpc_connector_config = {
    subnetwork = var.subnets.net-office-0-snet-mw1-dev-vpc-connector
  }
}
```

Create the VPC-Connector outside the module and specify the VPC-Connector name:
```
module "labels-checker" {
  source = "./modules/labels-checker"
  project_id = var.project_id
  environment_variables = {
    EMAIL_TO   = "devops-team@exmaple.com"
    EMAIL_FROM = "security-alerts@exmaple.com"
  }
  vpc_connector = {
    create = false
    name = "my-vpc-connector" # required when create is set to `false`
  }
  vpc_connector_config = {
    subnetwork = var.subnets.net-office-0-snet-mw1-dev-vpc-connector
  }
}
```

### Service account management
To use a custom service account managed by the module, set service_account_create to true and leave service_account set to null value (default).

Create Service-Account within the module:
This module asign the role `roles/broswer` on the specified `FOLDER_NUMBER` configured on `environment_variables`.
```
module "labels-checker" {
  source = "./modules/labels-checker"
  project_id = var.project_id
  environment_variables = {
    EMAIL_TO   = "devops-team@exmaple.com"
    EMAIL_FROM = "security-alerts@exmaple.com"
  }
  service_account_create = true
  vpc_connector = {
    create = false
    name = "my-vpc-connector" # required when create is set to `false`
  }
  vpc_connector_config = {
    subnetwork = var.subnets.net-office-0-snet-mw1-dev-vpc-connector
  }
}
```

To use an externally managed service account, pass its email in `service_account` and leave `service_account_create` to false (the default).  
Service account needs `resourcemanager.folders.list` permission in order to scan all project the folder contains. The role `role/browser` can be grated on the relevent folder.  
```
module "labels-checker" {
  source = "./modules/labels-checker"
  project_id = var.project_id
  environment_variables = {
    EMAIL_TO   = "devops-team@exmaple.com"
    EMAIL_FROM = "security-alerts@exmaple.com"
  }
  service_account = module.labels-checker-sa.email
  vpc_connector = {
    create = false
    name = "my-vpc-connector" # required when create is set to `false`
  }
  vpc_connector_config = {
    subnetwork = var.subnets.net-office-0-snet-mw1-dev-vpc-connector
  }
}
```

### Cloud scheduler management
To override default values of cloud-scheduler, pass its scheduler variables under `function_scheduler' variable.  
default values are: name: labels-checker-job region: europe-west3, schedule: "0 7 * * 0" (7AM every Sunday), time_zone: Asia/Jerusalem.  
>**Notes:** 
Region is not supported in me-west1

```
module "labels-checker" {
  source = "./modules/labels-checker"
  project_id = var.project_id
  environment_variables = {
    EMAIL_TO   = "devops-team@exmaple.com"
    EMAIL_FROM = "security-alerts@exmaple.com"
  }
  service_account = module.labels-checker-sa.email
  function_scheduler = {
    name     = "labels-checker-scheduler"
    schedule = "0 8 * * 0" # every 8AM of every Sunday
  }
  vpc_connector = {
    create = false
    name = "my-vpc-connector" # required when create is set to `false`
  }
  vpc_connector_config = {
    subnetwork = var.subnets.net-office-0-snet-mw1-dev-vpc-connector
  }
}
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [environment_variables](variables.tf#L24) | Cloud function environment variables. | <code title="object&#40;&#123;&#10;  EMAIL_FROM    &#61; string&#10;  EMAIL_TO      &#61; string&#10;  FOLDER_NUMBER &#61; string&#10;  SMTP_PORT     &#61; optional&#40;string&#41;&#10;  SMTP_SERVER   &#61; optional&#40;string, &#34;smtp.dgt.gcp.internal&#34;&#41;&#10;  SUBJECT       &#61; optional&#40;string, &#34;Alert: Unlabeled GCP Projects&#34;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [project_id](variables.tf#L78) | Project id used for all resources. | <code>string</code> | ✓ |  |
| [vpc_connector](variables.tf#L101) | VPC connector configuration. Set create to 'true' if a new connector needs to be created. | <code title="object&#40;&#123;&#10;  create          &#61; optional&#40;bool, true&#41;&#10;  name            &#61; optional&#40;string, &#34;vpc-connector&#34;&#41;&#10;  egress_settings &#61; optional&#40;string, &#34;ALL_TRAFFIC&#34;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [vpc_connector_config](variables.tf#L110) | VPC connector network configuration. Must be provided if new VPC connector is being created. | <code title="object&#40;&#123;&#10;  subnetwork     &#61; string&#10;  min_instances  &#61; optional&#40;number, 2&#41;&#10;  max_instances  &#61; optional&#40;number, 10&#41;&#10;  machine_type   &#61; optional&#40;string, &#34;e2-micro&#34;&#41;&#10;  max_throughput &#61; optional&#40;number, 1000&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [build_service_account](variables.tf#L18) | Build service account email. | <code>string</code> |  | <code>null</code> |
| [function_config](variables.tf#L36) | Cloud function configuration. Defaults to using main as entrypoint, 1 instance with 256MiB of memory, and 180 second timeout. | <code title="object&#40;&#123;&#10;  entry_point     &#61; optional&#40;string, &#34;labels_checker&#34;&#41;&#10;  instance_count  &#61; optional&#40;number, 1&#41;&#10;  memory_mb       &#61; optional&#40;number, 256&#41; &#35; Memory in MB&#10;  cpu             &#61; optional&#40;string, &#34;0.166&#34;&#41;&#10;  runtime         &#61; optional&#40;string, &#34;python310&#34;&#41;&#10;  timeout_seconds &#61; optional&#40;number, 180&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  entry_point     &#61; &#34;labels_checker&#34;&#10;  instance_count  &#61; 1&#10;  memory_mb       &#61; 256&#10;  cpu             &#61; &#34;0.166&#34;&#10;  runtime         &#61; &#34;python310&#34;&#10;  timeout_seconds &#61; 180&#10;&#125;">&#123;&#8230;&#125;</code> |
| [function_scheduler](variables.tf#L56) | Cloud function scheduler resource | <code title="object&#40;&#123;&#10;  name      &#61; string&#10;  schedule  &#61; string&#10;  region    &#61; string&#10;  time_zone &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  name      &#61; &#34;labels-checker-job&#34;&#10;  schedule  &#61; &#34;0 7 &#42; &#42; 0&#34;&#10;  region    &#61; &#34;europe-west3&#34;&#10;  time_zone &#61; &#34;Asia&#47;Jerusalem&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [labels](variables.tf#L72) | Resource labels. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [region](variables.tf#L83) | Region used for all resources. | <code>string</code> |  | <code>&#34;me-west1&#34;</code> |
| [service_account](variables.tf#L89) | Service account email. Unused if service account is auto-created. | <code>string</code> |  | <code>null</code> |
| [service_account_create](variables.tf#L95) | Auto-create service account. | <code>bool</code> |  | <code>false</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [cloud_function](outputs.tf#L18) | Cloud function resource. |  |
| [function_scheduler](outputs.tf#L33) | Scheduler job resource. |  |
| [service_account](outputs.tf#L23) | Service account resource. |  |
| [service_account_email](outputs.tf#L28) | Service account email. |  |
| [vpc_connector](outputs.tf#L38) | VPC connector resource. |  |
<!-- END TFDOC -->
