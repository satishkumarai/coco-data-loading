-- ==============================================================================
-- copy_into_backfill.sql
-- Production Warehouse-Optimized Bulk Ingestion & Backfill Workflows
-- ==============================================================================

-- 1. Create Destination Table Dynamically using Schema Template from Staged Files
CREATE OR REPLACE TABLE RAW_DB.INGEST_SCHEMA.HISTORICAL_ORDERS_BACKFILL
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
    FROM TABLE(
      INFER_SCHEMA(
        LOCATION => '@RAW_DB.INGEST_SCHEMA.STAGE_AZURE_ORDERS/historical/2026/',
        FILE_FORMAT => 'RAW_DB.INGEST_SCHEMA.FF_CSV_OPTIMIZED'
      )
    )
  )
  ENABLE_SCHEMA_EVOLUTION = TRUE
  COMMENT = 'Historical backfill table created directly from inferred file schema';

-- 2. Execute Bulk Load with Warehouse Parallelism & Case-Insensitive Column Matching
-- Note: Warehouse size should be scaled (e.g., L or XL) proportionally to staged file volume
COPY INTO RAW_DB.INGEST_SCHEMA.HISTORICAL_ORDERS_BACKFILL
FROM @RAW_DB.INGEST_SCHEMA.STAGE_AZURE_ORDERS/historical/2026/
FILE_FORMAT = (FORMAT_NAME = 'RAW_DB.INGEST_SCHEMA.FF_CSV_OPTIMIZED')
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
ON_ERROR = ABORT_STATEMENT
PURGE = FALSE
RETURN_FAILED_ONLY = FALSE;

-- 3. High-Resilience Bulk Load with Error Skipping & Validation Mode Dry-Run
-- Step 3a: Perform Dry-Run Validation (Syntax & Type Verification without Inserting Data)
COPY INTO RAW_DB.INGEST_SCHEMA.HISTORICAL_ORDERS_BACKFILL
FROM @RAW_DB.INGEST_SCHEMA.STAGE_AZURE_ORDERS/historical/2026/
FILE_FORMAT = (FORMAT_NAME = 'RAW_DB.INGEST_SCHEMA.FF_CSV_OPTIMIZED')
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
VALIDATION_MODE = RETURN_ERRORS;

-- Step 3b: Execute with SKIP_FILE on Malformed Records
COPY INTO RAW_DB.INGEST_SCHEMA.HISTORICAL_ORDERS_BACKFILL
FROM @RAW_DB.INGEST_SCHEMA.STAGE_AZURE_ORDERS/historical/2026/
FILE_FORMAT = (FORMAT_NAME = 'RAW_DB.INGEST_SCHEMA.FF_CSV_OPTIMIZED')
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
ON_ERROR = SKIP_FILE_3%
PURGE = FALSE;

-- 4. Audit Post-Load Row Count and Data Integrity
SELECT
  COUNT(*) AS total_rows_loaded,
  COUNT(DISTINCT order_id) AS distinct_orders,
  MIN(order_date) AS earliest_order_date,
  MAX(order_date) AS latest_order_date
FROM RAW_DB.INGEST_SCHEMA.HISTORICAL_ORDERS_BACKFILL;
