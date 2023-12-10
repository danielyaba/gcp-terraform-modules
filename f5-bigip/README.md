# F5 BigIP-VE HA active-standby Module

## Design Notes
* The blueprint supports by default 3 VPCs: external, internal and management networks.
* We don't use the F5 Cloud Failover Extension (CFE). it would use static routes and it would require F5-BigIP VMs service account to have roles set, so they can configure routes, and/or alias IP's.
* This module deploys 2 F5 BigIP VMs, each in an unmanaged instance group, in a dedicated zone.
* Every F5-BigIP instance has only two ingress virtual-servers, each one for every Google-Load-Balancer.
* The blueprint allows to expose the F5 instances both externally and internally, using internal and external load balancers. This deployment exposes the same F5 instances both externally and internally at the same time with backend instance-groups.
* We use a modified F5-BigIP f5-onboard.tmpl file for initial configurations, cluster sync and failover
* All initial setup is configured with F5-Declerative-Onboarding RPM (Currently the only RPM supported in this module)
* Default provisioned modules are LTM and ASM. Change myProvisioning section in f5_onboard.tmpl in order to enable and/or disable modules (ASM, LTM, APM etc.)
* Every configuration based on traffic-group-1 is synced between F5-BigIP instances
* Make sure to specify Google-Internal-Load-Balancer IP address to the module in order create virtual server on the corresponding IP of GCP-ILB
* Only Active F5-BigIP instance is serving traffic. Virtual-servers on standby unit is on disabled state
* When machine goes standby vitual-servers changing mode to disabled state and when machine goes active virtual-servers changing mode to enabled

The default username is admin and the password is Default123456!

## F5 Configuration
You won't be able to pass traffic through the F5 load balancers until you perform some further configurations.
* Enable ```automap``` so that traffic is source natted using the self IPs configured, before going to the backends.
* Create as many virtual servers/irules as you need, so you can match incoming traffic and redirect it to the backends
* virtual server ```virt_INT-INGRESS-CONTROLLER``` configured for traffic coming from Google internal load balancer
* virtual server ```virt_EXT-INGRESS-CONTROLLER``` configured for traffic coming from Google external load balancer
* iRule ```irule_ENGRESS_CONTROLLER``` is for routing traffic based on hostname and/or pathes to internal virtual servers or backend pools
* Configure Google load balancers' health checks to query the F5 F5-BigIP VMs on port 443, iRule is already set to answer with TCP and HTTP (200 OK)


## Examples

### Active/Standby Instances With IP addresses
This example below creates F5-BigIP active/standby cluster along with IP addresses for management, external and internal NICs.

```
module "f5-bigip-cluster" {
  source     = "./modules/f5-bigip"
  prefix     = "f5-bigip"
  project_id = "my-project"
  region = "me-west1"

  vpc_config = {
    external = {
      subnetwork = subnetwork = "projects/my-project/regions/me-west1/subnetworks/external"
    }
    internal = {
      subnetwork = subnetwork = "projects/my-project/regions/me-west1/subnetworks/internal"
    }
    management = {
      subnetwork = subnetwork = "projects/my-project/regions/me-west1/subnetworks/managment"
    }
  }

  shared_instances_configs = {
    ilb_vip         = "1.2.3.4"
    service_account = "f5-bigip@my-project.iam.gserviceaccount.com"
    dns_suffix      = "example.com"
  }

  dedicated_instances_configs = {
    a = {
      license_key = "AAAA-BBBB-CCCC-DDDD-EEEEEEE"
    }
    b = {
      license_key = "AAAA-BBBB-CCCC-DDDD-EEEEEEE"
    }
  }
}
```

### Active/Standby Instances With IP addresses Pre-defined
This example below creates F5-BigIP active/standby cluster with pre-defined IP addresses sent to the module

```
module "f5-bigip-cluster" {
  source     = "./modules/f5-bigip"
  prefix     = "f5-bigip"
  project_id = "my-project"
  region = "me-west1"

  vpc_config = {
    external = {
      subnetwork = "projects/my-project/regions/me-west1/subnetworks/external"

    }
    internal = {
      subnetwork = "projects/my-project/regions/me-west1/subnetworks/internal"
    }
    management = {
     subnetwork = "projects/my-project/regions/me-west1/subnetworks/managment"
    }
  }

  shared_instances_configs = {
    ilb_vip         = "1.2.3.4"
    service_account = "f5-bigip@my-project.iam.gserviceaccount.com"
    dns_suffix      = "example.com"
  }

  dedicated_instances_configs = {
    a = {
      license_key = "AAAA-BBBB-CCCC-DDDD-EEEEEEE"
      network_addresses {
        managment = "10.10.0.10"
        external  = "10.10.2.10"
        internal  = "10.10.3.10"
      }
    }
    b = {
      license_key = "AAAA-BBBB-CCCC-DDDD-EEEEEEE"
      network_addresses {
        managment = "10.10.0.11"
        external  = "10.10.2.11"
        internal  = "10.10.3.11"
      }
    }
  }
}
```

## Download F5-Declerative-Onboarding RPM from GCS-Bucket
Inside ```data``` directory there is ```f5_onboard_gcs.tmpl``` template file:  
F5-BigIP instances will download RPMs from GCS bucket (bucket name should be specified in shared_instances_config declaration).  
Instructions: 
* Modify the template file under ```metadata_startup_script``` with the appropriate template file name
* Download the latest RPM from [F5-Declerative-Onboarding Github repository](https://github.com/F5Networks/f5-declarative-onboarding/releases) and locate the file under ```data``` directory
* Create a bucket and upload the file into the bucket:
Save the RPM in the bucket on the same directory as the file from Github
For example: f5-declerative-onboarding/v1.41.0/f5-declarative-onboarding-1.41.0-8.noarch.rpm
```
resource "google_storage_bucket" "f5-packages-bucket" {
  name          = "f5-rpms-bucket"
  location      = "ME-WEST1"
  force_destroy = true

  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_binding" "binding" {
  bucket = resource.google_storage_bucket.f5-rpms-bucket.name
  role = "roles/storage.objectUser"
  members = [
    "serviceAccount:"f5-bigip@my-project.iam.gserviceaccount.com"",
  ]
}

resource "google_storage_bucket_object" "picture" {
  name   = "f5-declerative-onboarding/<VERSION-OF-RPM>/<NAME-OF-DO-RPM>"
  source = "./data/<NAME-OF-DO-RPM>"
  bucket = resource.google_storage_bucket.f5-rpms-bucket.name
}
```

* specify the bucket name inside ```shared_intances_config``` variable under ```main.tf``` file:  
```
  shared_instances_configs = {
    f5_packages_bucket = resource.google_storage_bucket.f5-rpms-bucket.name
    ilb_vip            = "1.2.3.4"
    service_account    = "f5-bigip@my-project.iam.gserviceaccount.com"
    dns_suffix         = "example.com"
  }
```
* change locals section under ```main.tf``` file:
```
locals {
  _f5_urls = {
    do   = "gs://${var.shared_instances_configs.f5_packages_bucket}/f5-declarative-onboarding/v1.41.0/f5-declarative-onboarding-1.41.0-8.noarch.rpm"
  }
}
```




## Configure configSync and Failover on Management Subnetwork
Inside ```data``` directory there is ```f5_onboard_mgmt.tmpl``` template file:  
F5-BigIP cluster will be configured with configSync and failover with connectivity on the management NIC.  
Modify the template file under ```metadata_startup_script``` with appropriate temlapte file name.  
You can use ```f5_onboard_gcs_mgmt.tmpl``` for downloading RPMs from GCS bucket and configure configSync and failover with connectivity on the management NIC

## Create Instance-Group For Each Instance
In order to GLBs to forward traffic to the F5-BigIP VMs you should create an instance-group for every instance in each zone
The backends of the GLB will be those instance-groups
Create instance for each instance:
```
resource "google_compute_instance_group" "f5-bigip-a" {
  name        = "f5-bigip-a"
  description = "Terraform test instance group"
  instances = [
    module.f5-bigip-cluster.f5-bigip-a.id,
  ]
  named_port {
    name = "https"
    port = "443"
  }
  zone = "me-west1-a"
}

resource "google_compute_instance_group" "f5-bigip-b" {
  name        = "f5-bigip-b"
  description = "Terraform test instance group"
  instances = [
    module.f5-bigip-cluster.f5-bigip-b.id,
  ]
  named_port {
    name = "https"
    port = "443"
  }
  zone = "me-west1-b"
}

```


## Ingress Controller iRule
```
when HTTP_REQUEST {
    # route traffic to backend pool based on hostname
    if { [string tolower [HTTP::host]] equals "app1.example.com" } {
        pool pool_app1
    }

    # route traffic to backend pool based on path
    if { [string tolower [HTTP::path]] equals "/example1" } {
        pool pool_app1
    }

    # route traffic to internal virtual-server based on hostname
    if { [string tolower [HTTP::host]] equals "app1.example.com" } {
        virtual virt_app1
    }

    # route traffic internal virtual-server based on path
    if { [string tolower [HTTP::path]] equals "/example1" } {
        virtual virt_app1
    }
}
```

## F5 code copyright
This repository usees code from the third-party project terraform-gcp-bigip-module.

This code is also licensed as Apache 2.0.

This is the original copyright notice from the third-party repository: Copyright 2014-2019 F5 Networks Inc.

<!-- BEGIN TFDOC -->

## Variables
| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [dedicated_instances_configs](variables.tf#L1) | The F5 VMs configuration. The map keys are the zones where the VMs are deployed. | <code title="map&#40;object&#40;&#123;&#10;  license_key &#61; optional&#40;string, &#34;AAAAA-BBBBB-CCCCC-DDDDD-EEEEEEE&#34;&#41;&#10;  network_addresses &#61; optional&#40;object&#40;&#123;&#10;    external   &#61; optional&#40;string&#41;&#10;    internal   &#61; optional&#40;string&#41;&#10;    management &#61; optional&#40;string&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> | ✓ |  |
| [prefix](variables.tf#L13) | The prefix name used for resources. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L18) | The GCP project identifier where the cluster will be created. | <code>string</code> | ✓ |  |
| [region](variables.tf#L23) | The compute zones which will host the BIG-IP VMs. | <code>string</code> | ✓ |  |
| [shared_instances_configs](variables.tf#L29) | The F5 VMs shared configurations. | <code title="object&#40;&#123;&#10;  f5_packages_bucket &#61; string&#10;  boot_disk &#61; optional&#40;object&#40;&#123;&#10;    image &#61; optional&#40;string, &#34;projects&#47;f5-7626-networks-public&#47;global&#47;images&#47;f5-bigip-16-1-4-1-0-53-5-byol-all-modules-1boot-loc-1026112549&#34;&#41;&#10;    size  &#61; optional&#40;number, 100&#41;&#10;    type  &#61; optional&#40;string, &#34;pd-ssd&#34;&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  dns_server         &#61; optional&#40;string, &#34;169.254.169.254&#34;&#41;&#10;  dns_suffix         &#61; string&#10;  ilb_vip            &#61; string&#10;  labels             &#61; optional&#40;map&#40;string&#41;&#41;&#10;  machine_type       &#61; optional&#40;string, &#34;n2-standard-8&#34;&#41;&#10;  min_cpu_platform   &#61; optional&#40;string, &#34;Intel Cascade Lake&#34;&#41;&#10;  ntp_server         &#61; optional&#40;string, &#34;0.us.pool.ntp.org&#34;&#41;&#10;  password           &#61; optional&#40;string, &#34;Default123456&#33;&#34;&#41;&#10;  route_to_configure &#61; optional&#40;string&#41;&#10;  service_account    &#61; optional&#40;string&#41;&#10;  ssh_public_key     &#61; optional&#40;string, &#34;.&#47;data&#47;public.key&#34;&#41;&#10;  tags               &#61; optional&#40;list&#40;string&#41;&#41;&#10;  timezone           &#61; optional&#40;string, &#34;UTC&#34;&#41;&#10;  username           &#61; optional&#40;string, &#34;admin&#34;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [vpc_config](variables.tf#L55) | VPC configs for resources. | <code title="object&#40;&#123;&#10;  external &#61; object&#40;&#123;&#10;    subnetwork &#61; string&#10;  &#125;&#41;&#10;  internal &#61; object&#40;&#123;&#10;    subnetwork &#61; string&#10;  &#125;&#41;&#10;  management &#61; object&#40;&#123;&#10;    subnetwork &#61; string&#10;  &#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |

## Outputs
| name | description | sensitive |
|---|---|:---:|
| [f5-bigip-vms](outputs.tf#L1) | Details of every f5-bigip instance. |  |
| [shared_instances_configs](outputs.tf#L14) | Details of shared instances config. |  |

<!-- END TFDOC -->
