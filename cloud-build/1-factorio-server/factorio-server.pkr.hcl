variable "graftorio_addon" {
  type    = string
  default = ""
}

variable "image_family" {
  type    = string
  default = ""
}

variable "image_name" {
  type    = string
  default = ""
}

variable "image_zone" {
  type    = string
  default = ""
}

variable "project_id" {
  type    = string
  default = ""
}

source "googlecompute" "factorio" {
  image_description   = "https://github.com/jlucktay/factorio-server-kit - baked with Packer ${packer.version}"
  image_family        = var.image_family
  image_name          = var.image_name
  machine_type        = "c2d-standard-2"
  preemptible         = false
  project_id          = var.project_id
  source_image_family = "ubuntu-2004-lts"
  ssh_username        = "packer"
  tags                = ["ssh-from-world"]
  use_os_login        = true
  zone                = var.image_zone
}

build {
  description = "https://github.com/jlucktay/factorio-server-kit - Factorio"

  sources = ["source.googlecompute.factorio"]

  provisioner "file" {
    destination = "/tmp/"
    direction   = "upload"
    sources     = ["${path.root}/docker-run-factorio.sh", "${path.root}/toprc"]
  }

  provisioner "shell" {
    environment_vars = ["CLOUDSDK_CORE_PROJECT=${var.project_id}", "GRAFTORIO_ADDON=${var.graftorio_addon}"]
    execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    script           = "${path.root}/provisioner.sh"
  }
}
