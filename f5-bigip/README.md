# F5 BigIP-VE HA active-standby Module

## Design Notes
* The blueprint supports by default 3 VPCs: external, internal and management networks.
* We don't use the F5 Cloud Failover Extension (CFE). it would use static routes and it would require F5-BigIP VMs service account to have roles set, so they can configure routes, and/or alias IP's.
* This module deploys 2 F5 BigIP VMs, each in an unmanaged instance group, in a dedicated zone.
* Every F5-BigIP instance has only two ingress virtual-servers, each one for every Google-Load-Balancer.
* The blueprint allows to expose the F5 instances both externally and internally, using internal and external load balancers. This deployment exposes the same F5 instances both externally and internally at the same time with backend instance-groups.
* We use a modified F5-BigIP f5-onboard.tmpl file for initial configurations, cluster sync and failover
* All initial setup is configued with F5-Declerative-Onboarding RPM downloaded from accessible bucket to the intances service-account.
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
* Configure Google load balancers' health checks will query the F5 VMs on port 443, iRule is already set to answer with TCP and HTTP (200 OK)
* 

## Examples

### Active/Standby Instances With IP addresses

This example below creates F5-BigIP along with IP addresses for management, external and internal NICs.

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
    tags            = ["f5-lb-appliance"]
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

### Active/Standby Instances IP addresses Pre-defined
```
module "f5-bigip-cluster" {
  source     = "./modules/f5-bigip"
  prefix     = "f5-bigip"
  project_id = "my-project"
  region = "me-west1"

  vpc_config = {
    external = {
      subnetwork = "projects/my-project/regions/me-west1/subnetworks/external"
      external_address = "10.10.1.10"

    }
    internal = {
      subnetwork = "projects/my-project/regions/me-west1/subnetworks/internal"
      internal_address = "10.10.2.10"
    }
    management = {
     subnetwork = "projects/my-project/regions/me-west1/subnetworks/managment"
     management_address = "10.10.3.10"
    }
  }

  shared_instances_configs = {
    ilb_vip         = "1.2.3.4"
    service_account = "f5-bigip@my-project.iam.gserviceaccount.com"
    dns_suffix      = "example.com"
    tags            = ["f5-lb-appliance"]
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

## Ingress Controller iRule
```
when HTTP_REQUEST {
    # route traffic to backend pool based on hostname
    if { [string tolower [HTTP::host]] equals "app1.example.com" } {
        pool app1
    }

    # route traffic to backend pool based on path
    if { [string tolower [HTTP::path]] equals "/example1" } {
        pool app1
    }
}
```

## F5 code copyright

