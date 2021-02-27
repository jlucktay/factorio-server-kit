terraform {
  backend "gcs" {}

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.58.0"
    }
  }

  required_version = ">= 0.13"
}
