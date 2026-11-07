output "sqs_queue_arn" {
  description = "ARN of the SQS queue delivering bucket notifications to Snowpipe"
  value       = aws_sqs_queue.snowpipe_queue.arn
}

output "storage_role_arn" {
  description = "ARN of the IAM role assumed by Snowflake Storage Integration"
  value       = aws_iam_role.snowflake_storage_role.arn
}
