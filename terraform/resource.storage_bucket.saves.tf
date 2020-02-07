resource "google_storage_bucket" "saves" {
  count = length(local.locations_json)

  name = format(
    "%s-saves-%s",
    var.project_id,
    element(local.locations_json, count.index).location,
  )

  location = substr(
    element(local.locations_json, count.index).zone,
    0,
    length(element(local.locations_json, count.index).zone) - 2
  )
}
