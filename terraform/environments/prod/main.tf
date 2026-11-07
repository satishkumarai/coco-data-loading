terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.87"
    }
  }
}

# Production Multi-Cloud Ingestion Module Instantiation

module "aws_events_ingest" {
  source                 = "../../modules/aws_snowpipe"
  environment            = "prod"
  pipeline_name          = "enterprise-events"
  s3_bucket_name         = "production-enterprise-data-lake-useast1"
  s3_bucket_arn          = "arn:aws:s3:::production-enterprise-data-lake-useast1"
  s3_prefix              = "raw/events/"
  snowflake_iam_user_arn = "arn:aws:iam::123456789012:user/snowflake-service-user"
  snowflake_external_id  = "SNOWFLAKE_PROD_EXT_ID_12345"
}
