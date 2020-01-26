resource "google_storage_bucket" "saves" {
  count = length(jsondecode(file("${path.module}/../lib/locations.json")))

  name = format(
    "%s-saves-%s",
    var.project_id,
    element(
      jsondecode(
        file("${path.module}/../lib/locations.json")
      ),
      count.index
    ).location,
  )

  location = substr(
    element(
      jsondecode(
        file("${path.module}/../lib/locations.json")
      ),
      count.index
    ).zone,
    0,
    length(
      element(
        jsondecode(
          file("${path.module}/../lib/locations.json")
        ),
        count.index
      ).zone
    ) - 2
  )
}
