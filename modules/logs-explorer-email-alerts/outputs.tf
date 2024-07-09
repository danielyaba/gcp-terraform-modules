/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

output "log_sinks" {
  description = "Log sinks resources."
  value = {
    for k, v in google_logging_folder_sink.sink : k => v
  }
}

output "pubsub_topic" {
  description = "Pub/Sub topic resource"
  value       = google_pubsub_topic.topic
}

output "cloud_functions" {
  description = "Cloud function resources."
  value = {
    for k, v in google_cloudfunctions2_function.function : k => v
  }
}

output "service_account" {
  description = "Service account resource."
  value       = google_service_account.service_account
}

output "vpc_connector" {
  description = "VPC connector resource."
  value       = try(google_vpc_access_connector.connector[0].id, null)
}
