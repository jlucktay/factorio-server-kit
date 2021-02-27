resource "google_cloud_scheduler_job" "cleanup_disks" {
  name        = "cleanup-disks"
  description = "Trigger the cleanup-disks Cloud Function once every day (using primes)"
  schedule    = "53 19 * * *"
  time_zone   = "Etc/UTC"

  pubsub_target {
    # topic.id is the topic's full resource name.
    topic_name = google_pubsub_topic.cleanup_disks.id
    data       = base64encode("{}")
  }
}

resource "google_cloud_scheduler_job" "cleanup_instances" {
  name        = "cleanup-instances"
  description = "Trigger the cleanup-instances Cloud Function every 15 minutes"
  schedule    = "*/15 * * * *"
  time_zone   = "Etc/UTC"

  pubsub_target {
    # topic.id is the topic's full resource name.
    topic_name = google_pubsub_topic.cleanup_instances.id
    data       = base64encode("{}")
  }
}
