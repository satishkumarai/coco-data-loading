variable "environment" {
  type        = string
  description = "Deployment environment"
  default     = "prod"
}

variable "pipeline_name" {
  type        = string
  description = "Logical identifier for the GCP Snowpipe pipeline"
}

variable "bucket_name" {
  type        = string
  description = "Name of the Google Cloud Storage bucket"
}

variable "object_prefix" {
  type        = string
  description = "GCS object path prefix to filter notifications"
  default     = "iot/readings/"
}
