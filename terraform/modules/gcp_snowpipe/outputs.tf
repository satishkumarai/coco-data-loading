output "pubsub_topic_id" {
  description = "GCP Pub/Sub Topic ID"
  value       = google_pubsub_topic.snowpipe_topic.id
}

output "pubsub_subscription_id" {
  description = "GCP Pub/Sub Subscription ID"
  value       = google_pubsub_subscription.snowpipe_subscription.id
}
