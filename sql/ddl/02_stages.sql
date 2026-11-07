-- ==============================================================================
-- 02_stages.sql
-- External Stage & External Volume Definitions for Multi-Cloud Ingestion
-- ==============================================================================

-- 1. AWS S3 External Stage (Using cross-account Storage Integration)
CREATE OR REPLACE STAGE RAW_DB.INGEST_SCHEMA.STAGE_AWS_S3_EVENTS
  URL = 's3://production-enterprise-data-lake-useast1/raw/events/'
  STORAGE_INTEGRATION = SI_AWS_S3_PROD
  FILE_FORMAT = RAW_DB.INGEST_SCHEMA.FF_PARQUET_VECTORIZED
  DIRECTORY = (ENABLE = TRUE, AUTO_REFRESH = TRUE)
  COMMENT = 'External stage for AWS S3 real-time event landing zone';

-- 2. Azure Blob / ADLS Gen2 External Stage
CREATE OR REPLACE STAGE RAW_DB.INGEST_SCHEMA.STAGE_AZURE_ORDERS
  URL = 'azure://prodlakehouseadls.blob.core.windows.net/raw/orders/'
  STORAGE_INTEGRATION = SI_AZURE_BLOB_PROD
  FILE_FORMAT = RAW_DB.INGEST_SCHEMA.FF_CSV_OPTIMIZED
  DIRECTORY = (ENABLE = TRUE, AUTO_REFRESH = TRUE)
  COMMENT = 'External stage for Azure ADLS Gen2 transactional order feeds';

-- 3. Google Cloud Storage (GCS) External Stage
CREATE OR REPLACE STAGE RAW_DB.INGEST_SCHEMA.STAGE_GCS_TELEMETRY
  URL = 'gcs://prod-telemetry-lake-gcp/iot/readings/'
  STORAGE_INTEGRATION = SI_GCP_GCS_PROD
  FILE_FORMAT = RAW_DB.INGEST_SCHEMA.FF_NDJSON
  DIRECTORY = (ENABLE = TRUE, AUTO_REFRESH = TRUE)
  COMMENT = 'External stage for GCP IoT device telemetry stream';

-- 4. External Volume for Customer-Managed Apache Iceberg Storage (BYOS)
CREATE OR REPLACE EXTERNAL VOLUME EV_ICEBERG_CUSTOMER_STORAGE
  STORAGE_LOCATIONS =
    (
      (
        NAME = 'us-east-1-iceberg-ext'
        TYPE = S3
        STORAGE_BASE_URL = 's3://production-iceberg-lakehouse-useast1/tables/'
        STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::123456789012:role/snowflake.com/IcebergStorageRole'
      )
    )
  COMMENT = 'External volume for Iceberg tables requiring customer-managed cloud storage';
