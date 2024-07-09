# Google Logs Explorer Email Alert Module

This module allows creating one or more email alerts based on log filters from Google Logs Explorer.  

It creates a single Cloud-Function **FOR EACH** email alert sent to the module.   
It creates a single Pub/Sub topic, GCS Bucket, VPC-Connector and Service-Account for all email alerts.  

## TODO
* add support for GCS bucket creation and configuration
* add support for specifying docker repository id
* add support for trigger alert on project creation event
* add support for service account management

## Prerequisites
1. Make sure the following API services are enabled on you project:
* cloudbuild.googleapis.com
* eventarc.googleapis.com
* run.googleapis.com
* vpcaccess.googleapis.com 

2. Make sure that vpc connector subnet with `/28` is exists in the VPC.  For example under dev VPC:

3. Make sure vpc-connector has relevant FW ingress rules from serverless infrastructure:  
Ingress rules:  
sources IP: 35.199.224.0/19.  
target tags: vpc-connector. 

## Examples:
Note: `environment_variables` must be in captial letters.  

### Basic example:
```
module "alert-notify" {
  source = ./modules/alert-notify"
  project_id = var.project_id
  folder_id = var.folder_ids.office
  email_alert = {
    vm-instance-creation = {
      description = "Cloud-Function for sending email alerts for every creation of VM instance"
      log_filter = "protoPayload.methodName=beta.compute.instances.insert"
      environment_variables = {
        SUBJECT    = "Alert: Instance Created"
        DISCLAIMER = "A Compute-VM instance has created"
        EMAIL_TO   = "devops-team@exmaple.com"
        EMAIL_FROM = "security-alerts@exmaple.com"
      }
    }
  }
  vpc_connector = {
    create = true
  }
  vpc_connector_config = {
    subnetwork = var.subnets.net-office-0-snet-mw1-dev-vpc-connector
  }
}
```

### Using locals
Using local simplifies the creation of email alerts without changing anything in the module declaration.  
Adding email-alert should be added under `email-alerts` variable.  
```
locals {
  email_alerts = {
    vm-instances-creation = {
      log_filter  = "protoPayload.methodName=beta.compute.instances.insert"
      description = "Cloud-function for VM instances creation alerts"
      environment_variables = {
        SUBJECT    = "Alert: Instance Created"
        DISCLAIMER = "A Compute-VM instance has created"
        EMAIL_TO   = "devops-team@exmaple.com"
        EMAIL_FROM = "security-alerts@exmaple.com"
      }
    }
  }
}

module "alert-notify" {
  source     = "../../../../modules/alert-notify"
  project_id = module.project.project_id
  folder_id  = var.folder_ids.office
  email_alerts = local.email_alerts
  vpc_connector = {
    create = true
  }
  vpc_connector_config = {
    subnetwork = var.subnets.net-office-0-snet-mw1-dev-vpc-connector
  }
}
```

### VPC-Connector
This module supports creation of VPC-Connector along with Cloud-Function.  
Specifying `create = true` under `vpc_connector` variable will cause the module to create the VPC-Connector with the name `vpc-connector` (default name can be overriden with `name = <VPC-CONNECTOR-NAME>`).  
>**Notes:**   
Without VPC-Connector the function will not be operational.  
If you are planning to have multiple Cloud-Functions it is recommended to create the VPC-Connector outside the module.


Create VPC-Connector within the module:
```
module "alert-notify" {
  source = ./modules/alert-notify"
  project_id = var.project_id
  folder_id = var.folder_ids.office
  email_alert = {
    vm-instance-creation = {
      description = "Cloud-Function for sending email alerts for every creation of VM instance"
      log_filter = "protoPayload.methodName=beta.compute.instances.insert"
      environment_variables = {
        SUBJECT    = "Alert: Instance Created"
        DISCLAIMER = "A Compute-VM instance has created"
        EMAIL_TO   = "devops-team@exmaple.com"
        EMAIL_FROM = "security-alerts@exmaple.com"
      }
    }
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
module "alert-notify" {
  source = ./modules/alert-notify"
  project_id = var.project_id
  folder_id = var.folder_ids.office
  email_alert = {
    vm-instance-creation = {
      description = "Cloud-Function for sending email alerts for every creation of VM instance"
      log_filter = "protoPayload.methodName=beta.compute.instances.insert"
      environment_variables = {
        SUBJECT    = "Alert: Instance Created"
        DISCLAIMER = "A Compute-VM instance has created"
        EMAIL_TO   = "devops-team@exmaple.com"
        EMAIL_FROM = "security-alerts@exmaple.com"
      }
    }
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
| [email_alerts](variables.tf#L24) | Email alerts. | <code title="map&#40;object&#40;&#123;&#10;  description &#61; optional&#40;string, &#34;Terraform managed.&#34;&#41;&#10;  log_filter  &#61; string&#10;  environment_variables &#61; object&#40;&#123;&#10;    DISCLAIMER  &#61; string&#10;    EMAIL_FROM  &#61; string&#10;    EMAIL_TO    &#61; string&#10;    SMTP_PORT   &#61; optional&#40;string&#41;&#10;    SMTP_SERVER &#61; optional&#40;string, &#34;smtp.dgt.gcp.internal&#34;&#41;&#10;    SUBJECT     &#61; string&#10;  &#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> | ✓ |  |
| [folder_id](variables.tf#L40) | Folder id in format folders/[FOLDER_ID] . | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L77) | Project id used for all resources. | <code>string</code> | ✓ |  |
| [vpc_connector](variables.tf#L100) | VPC connector configuration. Set create to 'true' if a new connector needs to be created. | <code title="object&#40;&#123;&#10;  create          &#61; optional&#40;bool, true&#41;&#10;  name            &#61; optional&#40;string, &#34;vpc-connector&#34;&#41;&#10;  egress_settings &#61; optional&#40;string, &#34;ALL_TRAFFIC&#34;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [vpc_connector_config](variables.tf#L109) | VPC connector network configuration. Must be provided if new VPC connector is being created. | <code title="object&#40;&#123;&#10;  subnetwork     &#61; string&#10;  min_instances  &#61; optional&#40;number, 2&#41;&#10;  max_instances  &#61; optional&#40;number, 10&#41;&#10;  machine_type   &#61; optional&#40;string, &#34;e2-micro&#34;&#41;&#10;  max_throughput &#61; optional&#40;number, 1000&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [build_service_account](variables.tf#L18) | Build service account email. | <code>string</code> |  | <code>null</code> |
| [function_config](variables.tf#L45) | Cloud function configuration. Defaults to using main as entrypoint, 1 instance with 256MiB of memory, and 180 second timeout. | <code title="object&#40;&#123;&#10;  entry_point     &#61; optional&#40;string, &#34;get_topic_message&#34;&#41;&#10;  instance_count  &#61; optional&#40;number, 1&#41;&#10;  memory_mb       &#61; optional&#40;number, 256&#41; &#35; Memory in MB&#10;  cpu             &#61; optional&#40;string, &#34;0.166&#34;&#41;&#10;  runtime         &#61; optional&#40;string, &#34;python310&#34;&#41;&#10;  timeout_seconds &#61; optional&#40;number, 180&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  entry_point     &#61; &#34;get_topic_message&#34;&#10;  instance_count  &#61; 1&#10;  memory_mb       &#61; 256&#10;  cpu             &#61; &#34;0.166&#34;&#10;  runtime         &#61; &#34;python310&#34;&#10;  timeout_seconds &#61; 180&#10;&#125;">&#123;&#8230;&#125;</code> |
| [labels](variables.tf#L71) | Resource labels. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [region](variables.tf#L82) | Region used for all resources. | <code>string</code> |  | <code>&#34;me-west1&#34;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [cloud_functions](outputs.tf#L29) | Cloud function resources. |  |
| [log_sinks](outputs.tf#L17) | Log sinks resources. |  |
| [pubsub_topic](outputs.tf#L24) | Pub/Sub topic resource |  |
| [service_account](outputs.tf#L36) | Service account resource. |  |
| [vpc_connector](outputs.tf#L41) | VPC connector resource. |  |
<!-- END TFDOC -->
