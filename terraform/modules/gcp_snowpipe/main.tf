terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# 1. GCP Pub/Sub Topic for GCS Object Notifications
resource "google_pubsub_topic" "snowpipe_topic" {
  name = "${var.pipeline_name}-gcs-notifications"

  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# 2. GCP Pub/Sub Subscription for Snowflake Pull Integration
resource "google_pubsub_subscription" "snowpipe_subscription" {
  name  = "${var.pipeline_name}-snowpipe-sub"
  topic = google_pubsub_topic.snowpipe_topic.name

  ack_deadline_seconds       = 300
  message_retention_duration = "604800s" # 7 days
  retain_acked_messages      = false

  enable_message_ordering = false
}

# 3. GCS Bucket Notification Configuration (OBJECT_FINALIZE)
resource "google_storage_notification" "notification" {
  bucket         = var.bucket_name
  payload_format = "JSON_API_V1"
  topic          = google_pubsub_topic.snowpipe_topic.id
  event_types    = ["OBJECT_FINALIZE"]
  object_name_prefix = var.object_prefix

  depends_on = [google_pubsub_topic.snowpipe_topic]
}
