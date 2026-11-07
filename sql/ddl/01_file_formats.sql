-- ==============================================================================
-- 01_file_formats.sql
-- Production File Format Definitions Optimized for Snowflake Ingestion (CoCo GA)
-- ==============================================================================

-- 1. Optimized CSV File Format (Single-line records for maximum parallel splitting)
CREATE OR REPLACE FILE FORMAT RAW_DB.INGEST_SCHEMA.FF_CSV_OPTIMIZED
  TYPE = 'CSV'
  RECORD_DELIMITER = '\n'
  FIELD_DELIMITER = ','
  PARSE_HEADER = TRUE
  MULTI_LINE = FALSE
  COMPRESSION = AUTO
  ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  NULL_IF = ('', 'NULL', 'null', '\\N')
  COMMENT = 'Optimized single-line CSV format with header parsing and parallel scan support';

-- 2. Multi-line CSV Format (For files containing line breaks within quoted fields)
CREATE OR REPLACE FILE FORMAT RAW_DB.INGEST_SCHEMA.FF_CSV_MULTILINE
  TYPE = 'CSV'
  RECORD_DELIMITER = '\n'
  FIELD_DELIMITER = ','
  PARSE_HEADER = TRUE
  MULTI_LINE = TRUE
  COMPRESSION = AUTO
  ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  NULL_IF = ('', 'NULL', 'null', '\\N')
  COMMENT = 'Multi-line CSV format supporting embedded line breaks in text fields';

-- 3. Newline-Delimited JSON (NDJSON / JSONL) Format
CREATE OR REPLACE FILE FORMAT RAW_DB.INGEST_SCHEMA.FF_NDJSON
  TYPE = 'JSON'
  MULTI_LINE = FALSE
  STRIP_OUTER_ARRAY = FALSE
  COMPRESSION = AUTO
  ALLOW_DUPLICATE = FALSE
  COMMENT = 'High-throughput newline-delimited JSON format for streaming and micro-batch';

-- 4. Single Top-Level Array JSON Format
CREATE OR REPLACE FILE FORMAT RAW_DB.INGEST_SCHEMA.FF_JSON_ARRAY
  TYPE = 'JSON'
  MULTI_LINE = TRUE
  STRIP_OUTER_ARRAY = TRUE
  COMPRESSION = AUTO
  COMMENT = 'JSON format for loading files containing top-level array of JSON objects';

-- 5. Performance-Tuned Parquet Format (Vectorized Scanner + Logical Types)
CREATE OR REPLACE FILE FORMAT RAW_DB.INGEST_SCHEMA.FF_PARQUET_VECTORIZED
  TYPE = 'PARQUET'
  USE_VECTORIZED_SCANNER = TRUE
  USE_LOGICAL_TYPE = TRUE
  BINARY_AS_TEXT = FALSE
  COMPRESSION = AUTO
  COMMENT = 'Parquet format leveraging SIMD vectorized scanner and preserved Spark/pandas logical types';

-- 6. Apache Avro File Format
CREATE OR REPLACE FILE FORMAT RAW_DB.INGEST_SCHEMA.FF_AVRO
  TYPE = 'AVRO'
  COMPRESSION = AUTO
  COMMENT = 'Standard Avro ingestion format with auto-detected compression';

-- 7. Apache ORC File Format
CREATE OR REPLACE FILE FORMAT RAW_DB.INGEST_SCHEMA.FF_ORC
  TYPE = 'ORC'
  COMPRESSION = AUTO
  COMMENT = 'Optimized ORC columnar format';
