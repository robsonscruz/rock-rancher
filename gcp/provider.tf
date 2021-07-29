provider "google" {
  credentials = file(var.credentials_json)
  project     = var.project
  region      = var.region
}