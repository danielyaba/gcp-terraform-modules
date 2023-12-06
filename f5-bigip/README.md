# F5 BigIP-VE HA active-standby Module

## Design Notes
* The blueprint supports by default 3 VPCs: a external, internal and management network.
* We don't use the F5 Cloud Failover Extension (CFE). it would use static routes and it would require F5 VMs service accounts to have roles set, so they can configure routes.
* The blueprint allows to expose the F5 instances both externally and internally, using internal and external network passthrough load balancers. You can also choose to expose the same F5 instances both externally and internally at the same time with backend instance-groups
* We deliberately a modified F5-BigIP f5-onboard.tmpl file for cluster sync and failover

The default username is admin and the password is Default123456!

## F5 Configuration
You won't be able to pass traffic through the F5 load balancers until you perform some further configurations.
* Enable ```automap``` so that traffic is source natted using the self IPs configured, before going to the backends.
* Create as many virtual servers/irules as you need, so you can match incoming traffic and redirect it to the backends
* virtual server ```virt_INT-INGRESS-CONTROLLER``` configured for traffic coming from Google internal load balancer
* virtual server ```virt_EXT-INGRESS-CONTROLLER``` configured for traffic coming from Google external load balancer
* iRule ```irule_ENGRESS_CONTROLLER``` is for routing traffic based on hostname and/or pathes to internal virtual servers or backend pools
* Configure Google load balancers' health checks will query the F5 VMs on port 443, iRule is already set to answer with TCP and HTTP (200 OK)
* Default provisioned modules are LTM and ASM. Change myProvisioning section in f5_onboard.tmpl in order to enable or disable modules (ASM, LTM, APM etc.)

## Examples

### Active/Standby Instances
```
module "f5-bigip-cluster" {
  source     = "./modules/f5-bigip"
  prefix     = "f5-bigip"
  project_id = "my-project"

  vpc_config = {
    external = {
      subnetwork = subnetwork = "projects/my-project/regions/europe-west1/subnetworks/external"
    }
    internal = {
      subnetwork = subnetwork = "projects/my-project/regions/europe-west1/subnetworks/internal"
    }
    management = {
      subnetwork = subnetwork = "projects/my-project/regions/europe-west1/subnetworks/managment"
    }
  }

  shared_instances_configs = {
    ilb_vip         = "1.2.3.4"
    service_account = "f5-bigip@my-project.iam.gserviceaccount.com"
    dns_suffix      = "example.com
    image           = "projects/f5-7626-networks-public/global/images/f5-bigip-16-1-4-1-0-53-5-byol-all-modules-1boot-loc-1026112549"
    tags            =["f5-lb-appliance"]
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

