-- ==============================================================================
-- 03_destination_tables.sql
-- Destination Tables with Dynamic Schema Evolution and Apache Iceberg Support
-- ==============================================================================

-- 1. Standard Destination Table with Automatic Schema Evolution Enabled
CREATE OR REPLACE TABLE RAW_DB.INGEST_SCHEMA.EVENTS_RAW
  ENABLE_SCHEMA_EVOLUTION = TRUE
  COMMENT = 'Standard Snowflake table with schema evolution enabled for continuous event stream'
AS
SELECT
  $1:event_id::VARCHAR AS event_id,
  $1:timestamp::TIMESTAMP_NTZ AS event_timestamp,
  $1:user_id::VARCHAR AS user_id,
  $1:payload::VARIANT AS payload
FROM @RAW_DB.INGEST_SCHEMA.STAGE_AWS_S3_EVENTS
LIMIT 0;

-- 2. Transactional Orders Table (Inferred schema baseline from CSV headers)
CREATE OR REPLACE TABLE RAW_DB.INGEST_SCHEMA.ORDERS_RAW (
  order_id VARCHAR NOT NULL,
  customer_id VARCHAR,
  order_date DATE,
  total_amount NUMBER(12, 2),
  status VARCHAR,
  ingested_at TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP()
)
ENABLE_SCHEMA_EVOLUTION = TRUE
COMMENT = 'Orders raw destination table with automatic evolution on new CSV fields';

-- 3. Snowflake-Managed Apache Iceberg™ Table (Snowflake-managed storage catalog)
CREATE OR REPLACE ICEBERG TABLE RAW_DB.INGEST_SCHEMA.ICEBERG_PAGEVIEWS_MANAGED (
  pageview_id STRING,
  visitor_id STRING,
  page_url STRING,
  referrer_url STRING,
  view_time TIMESTAMP,
  metadata VARIANT
)
CATALOG = 'SNOWFLAKE'
EXTERNAL_VOLUME = 'EV_ICEBERG_CUSTOMER_STORAGE'
BASE_LOCATION = 'pageviews_managed/'
ENABLE_SCHEMA_EVOLUTION = TRUE
COMMENT = 'Snowflake-managed Apache Iceberg table backed by external volume with full ACID snapshots';
