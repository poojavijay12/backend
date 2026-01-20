terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = "pooja31"
  region  = "asia-south1"
}

# -------------------------------
# Artifact Registry (Docker)
# -------------------------------
resource "google_artifact_registry_repository" "backend_repo" {
  location      = "asia-south1"
  repository_id = "backend-repo"
  format        = "DOCKER"
}

# -------------------------------
# Service Account for GitHub OIDC
# -------------------------------
resource "google_service_account" "github_sa" {
  account_id   = "github-gke-sa"
  display_name = "GitHub Actions GKE Deploy SA"
}

# -------------------------------
# IAM Roles
# -------------------------------
resource "google_project_iam_member" "gke_access" {
  project = "pooja31"
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.github_sa.email}"
}

resource "google_project_iam_member" "artifact_access" {
  project = "pooja31"
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.github_sa.email}"
}

# -------------------------------
# Workload Identity Pool
# -------------------------------
resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions Pool"
}

# -------------------------------
# Workload Identity Provider
# -------------------------------
resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# -------------------------------
# Allow GitHub Repo to Assume SA
# -------------------------------
resource "google_service_account_iam_member" "github_oidc_bind" {
  service_account_id = google_service_account.github_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/poojavijay12/backend"
}
