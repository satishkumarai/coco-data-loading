variable "environment" {
  type        = string
  description = "Target deployment environment (e.g., prod, stage, dev)"
  default     = "prod"
}

variable "pipeline_name" {
  type        = string
  description = "Logical name for the ingestion pipeline"
}

variable "s3_bucket_name" {
  type        = string
  description = "Name of the source S3 bucket"
}

variable "s3_bucket_arn" {
  type        = string
  description = "ARN of the source S3 bucket"
}

variable "s3_prefix" {
  type        = string
  description = "S3 prefix/folder path to ingest from"
  default     = "raw/events/"
}

variable "snowflake_iam_user_arn" {
  type        = string
  description = "Snowflake AWS IAM user ARN from STORAGE_INTEGRATION"
}

variable "snowflake_external_id" {
  type        = string
  description = "Snowflake External ID from STORAGE_INTEGRATION"
}
