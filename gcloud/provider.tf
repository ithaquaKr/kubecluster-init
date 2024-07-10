terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.36.0"
    }
  }
}

provider "google" {
  project     = var.project_name
  region      = var.region
  zone        = var.zone
  credentials = file("~/gcp-ithadev-nguyen-keys/ithadev-sa-pj-owner.json")
}
