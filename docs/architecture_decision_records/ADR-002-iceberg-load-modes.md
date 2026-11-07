# ADR-002: Ingestion Strategy for Snowflake-Managed Apache Iceberg™ Tables

## Status
Accepted

## Context
When loading data into Snowflake-managed Apache Iceberg™ tables via continuous Snowpipe or bulk COPY INTO, data engineers must determine whether to rewrite raw data into new Iceberg data files or register existing Parquet files directly into the Iceberg catalog.

## Decision
1. **LOAD_MODE = ADD_FILES_COPY**:
   - **Condition**: Must be used exclusively when source Parquet files have been produced by a compliant external Apache Iceberg writer (e.g., Spark Iceberg catalog, Trino Iceberg writer).
   - **Requirement**: Requires `USE_VECTORIZED_SCANNER = TRUE` and `MATCH_BY_COLUMN_NAME = CASE_SENSITIVE`.
   - **Benefit**: Zero compute rewrite cost; registers Parquet file metadata directly into Snowflake-managed Iceberg snapshots.

2. **LOAD_MODE = FULL_INGEST**:
   - **Condition**: Used for all standard formats (CSV, JSON, Avro, ORC) and Parquet files produced by non-Iceberg engines (pandas, standard PySpark write, custom ETL).
   - **Requirement**: Uses standard case-insensitive column matching and automatic schema evolution.
   - **Benefit**: Snowflake validates, organizes, and writes optimized Iceberg data files with complete statistics and partition metadata.

## Consequences
- Incorrectly applying `ADD_FILES_COPY` to generic Parquet files results in metadata parsing errors and catalog divergence.
