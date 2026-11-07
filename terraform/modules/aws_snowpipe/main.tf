terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.87"
    }
  }
}

# 1. AWS SQS Notification Queue for S3 Bucket Notifications
resource "aws_sqs_queue" "snowpipe_queue" {
  name                      = "${var.environment}-${var.pipeline_name}-snowpipe-queue"
  message_retention_seconds = 86400 # 24 hours
  receive_wait_time_seconds = 10

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Pipeline    = var.pipeline_name
  }
}

# 2. SQS Policy allowing S3 Bucket to publish ObjectCreated events
resource "aws_sqs_queue_policy" "snowpipe_queue_policy" {
  queue_url = aws_sqs_queue.snowpipe_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowS3Events"
        Effect    = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.snowpipe_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = var.s3_bucket_arn
          }
        }
      }
    ]
  })
}

# 3. S3 Bucket Notification Configuration
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = var.s3_bucket_name

  queue {
    queue_arn     = aws_sqs_queue.snowpipe_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = var.s3_prefix
  }

  depends_on = [aws_sqs_queue_policy.snowpipe_queue_policy]
}

# 4. AWS IAM Role for Snowflake Storage Integration
resource "aws_iam_role" "snowflake_storage_role" {
  name = "${var.environment}-${var.pipeline_name}-snowflake-storage-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = var.snowflake_iam_user_arn
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.snowflake_external_id
          }
        }
      }
    ]
  })
}

# 5. S3 Read Access Policy for Snowflake Storage Role
resource "aws_iam_role_policy" "snowflake_storage_policy" {
  name = "${var.environment}-${var.pipeline_name}-s3-access"
  role = aws_iam_role.snowflake_storage_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:GetObjectVersion"]
        Resource = "${var.s3_bucket_arn}/${var.s3_prefix}*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket", "s3:GetBucketLocation"]
        Resource = var.s3_bucket_arn
        Condition = {
          StringLike = {
            "s3:prefix" = ["${var.s3_prefix}*"]
          }
        }
      }
    ]
  })
}
