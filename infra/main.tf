terraform {
  required_version = ">= 0.14"

  required_providers {
    # Cloud Run support was added on 3.3.0
    google = ">= 3.3"
  }
}

variable "project_name" {
  type        = string
  description = "GCP Project Name"
}

variable "web_domain" {
  type        = string
  description = "Location where the web app will be deployed"
}

variable "location" {
  type        = string
  default     = "us-east1"
  description = "Cloud Location for GCP"
}

variable "tfstate_bucket_name" {
  type     = string
  default  = "${vars.project_name}-bucket-tfstate"
  descript = "bucket name for the tf state"
}

# Filename: main.tf# Configure GCP project
provider "google" {
  project = var.project_name
}

# Enables the Cloud Run API
resource "google_project_service" "run_api" {
  service = "run.googleapis.com"

  disable_on_destroy = true
}

resource "google_artifact_registry_repository" "my-repo" {
  location      = vars.location
  repository_id = "${vars.project_name}-repository"
  description   = "botter-repository"
  format        = "DOCKER"
}

## Create a bucket to store the terraform state
resource "google_storage_bucket" "default" {
  name          = vars.tfstate_bucket_name
  force_destroy = false
  location      = "US"
  storage_class = "STANDARD"
  versioning {
    enabled = true
  }
}

#https://cloud.google.com/docs/terraform/resource-management/store-state
terraform {
  backend "gcs" {
    bucket = vars.tfstate_bucket_name
    prefix = "terraform/state"
  }
}


# Deploy image to Cloud Run
resource "google_cloud_run_service" "app" {
  name     = "${vars.project_name}-app"
  location = vars.location
  template {
    spec {
      containers {
        image = "gcr.io/${vars.project_name}/app"
      }
    }
  }
  traffic {
    percent         = 100
    latest_revision = true
  }

  # Waits for the Cloud Run API to be enabled
  depends_on = [google_project_service.run_api]

}

# Create public access
data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

# Enable public access on Cloud Run service
resource "google_cloud_run_service_iam_policy" "noauth" {
  location    = google_cloud_run_service.app.location
  project     = google_cloud_run_service.app.project
  service     = google_cloud_run_service.app.name
  policy_data = data.google_iam_policy.noauth.policy_data
}

# Return service URL
output "url" {
  value = google_cloud_run_service.app.status[0].url
}

# note -> this still requires you point this domain at your app 
# from your DNS provider (unless the domain is owned by google cloud api)
# also note, this is distinct from domaisn.google.com
resource "google_cloud_run_domain_mapping" "app" {
  name     = vars.web_url
  location = vars.location
  metadata {
    namespace = vars.project_name
  }
  spec {
    route_name = google_cloud_run_service.app.name
  }
}
