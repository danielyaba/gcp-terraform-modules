# Terraform modules for Google Cloud Platform (GCP)

This repository provides Terraform modules for Google Cloud.   

Currently available modules:   
* Alerting Modules:
  * Alert-Notifier: Sending email alert for filter logs entries from Google Logs Explorer
  * Labels-Checker: Scans all GCP projects within a specified folder, identifies those missing labels or mandatory labels, and sends an email notification with the findings
  * F5-BigIP: Creating a BigIP cluster behind a GCP Internal Nework LB.
