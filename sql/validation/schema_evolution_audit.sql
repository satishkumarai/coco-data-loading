-- ==============================================================================
-- schema_evolution_audit.sql
-- Audit Schema Evolution Events and Track Structural Table Drift
-- ==============================================================================

-- 1. Query Schema Evolution History for Destination Tables
SELECT
  TABLE_NAME,
  SCHEMA_NAME,
  DATABASE_NAME,
  COLUMN_NAME,
  NEW_DATA_TYPE,
  EVOLUTION_KIND,
  ACTION_TRIGGERED_BY,
  TIMESTAMP AS evolution_timestamp
FROM TABLE(INFORMATION_SCHEMA.SCHEMA_EVOLUTION_RECORD(
  TABLE_NAME => 'RAW_DB.INGEST_SCHEMA.EVENTS_RAW'
))
ORDER BY evolution_timestamp DESC;

-- 2. Validate Current Column Definitions against Stage Inferred Schema
SELECT
  COLUMN_NAME,
  TYPE AS inferred_type,
  NULLABLE,
  EXPRESSION,
  FILENAMES
FROM TABLE(
  INFER_SCHEMA(
    LOCATION => '@RAW_DB.INGEST_SCHEMA.STAGE_AWS_S3_EVENTS',
    FILE_FORMAT => 'RAW_DB.INGEST_SCHEMA.FF_PARQUET_VECTORIZED'
  )
);

-- 3. Detect Column Data Type Mismatches or New Unmapped Columns
WITH inferred AS (
  SELECT
    COLUMN_NAME,
    TYPE AS inferred_type
  FROM TABLE(
    INFER_SCHEMA(
      LOCATION => '@RAW_DB.INGEST_SCHEMA.STAGE_AWS_S3_EVENTS',
      FILE_FORMAT => 'RAW_DB.INGEST_SCHEMA.FF_PARQUET_VECTORIZED'
    )
  )
),
existing AS (
  SELECT
    COLUMN_NAME,
    DATA_TYPE AS table_type
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = 'INGEST_SCHEMA'
    AND TABLE_NAME = 'EVENTS_RAW'
)
SELECT
  COALESCE(i.COLUMN_NAME, e.COLUMN_NAME) AS column_identifier,
  i.inferred_type AS incoming_file_type,
  e.table_type AS target_table_type,
  CASE
    WHEN e.COLUMN_NAME IS NULL THEN 'NEW_COLUMN_NEEDS_EVOLUTION'
    WHEN i.COLUMN_NAME IS NULL THEN 'TABLE_COLUMN_NOT_IN_SOURCE'
    WHEN i.inferred_type != e.table_type THEN 'DATA_TYPE_MISMATCH'
    ELSE 'SYNCHRONIZED'
  END AS synchronization_status
FROM inferred i
FULL OUTER JOIN existing e
  ON UPPER(i.COLUMN_NAME) = UPPER(e.COLUMN_NAME);
