resource "google_pubsub_topic" "cleanup_disks" {
  name = "cleanup-disks"
}

resource "google_pubsub_topic" "cleanup_instances" {
  name = "cleanup-instances"
}
