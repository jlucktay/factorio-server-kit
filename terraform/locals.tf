locals {
  locations_json = jsondecode(file("${path.module}/../lib/locations.json"))
}
