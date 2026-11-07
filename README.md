# Snowflake CoCo Continuous & Bulk File Loading Architecture

[![Snowflake](https://img.shields.io/badge/Snowflake-2026.10-29B5E8.svg)](https://docs.snowflake.com/)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![IaC](https://img.shields.io/badge/IaC-Terraform_1.5+-623CE4.svg)](https://www.terraform.io)

Production-grade reference implementation for automated continuous file ingestion (Snowpipe auto-ingest) and warehouse-optimized bulk data loading (COPY INTO) orchestrated via Snowflake Cortex Code (CoCo), Generally Available as of October 27, 2026.

---

## Table of Contents

- [Overview](#overview)
- [Repository Structure](#repository-structure)
- [Architectural Patterns](#architectural-patterns)
  - [1. Continuous Ingestion (Snowpipe Auto-Ingest)](#1-continuous-ingestion-snowpipe-auto-ingest)
  - [2. Bulk / Backfill Ingestion (COPY INTO)](#2-bulk--backfill-ingestion-copy-into)
  - [3. Managed Apache Iceberg™ Ingestion](#3-managed-apache-iceberg-ingestion)
- [Deployment Options](#deployment-options)
- [Security & Trust Boundaries](#security--trust-boundaries)
- [Performance & FinOps Benchmarks](#performance--finops-benchmarks)
- [Production Runbook & Observability](#production-runbook--observability)
- [References](#references)

---

## Overview

Historically, implementing continuous ingestion into Snowflake required cross-functional coordination:
1. Cloud IAM configuration (trust policies, least privilege role boundaries).
2. Cloud event routing (Amazon S3 Event Notifications / SQS, Azure Event Grid / Storage Queue, GCP Pub/Sub).
3. Snowflake storage and notification integrations.
4. Schema inference, file format optimization, staging, and Snowpipe DDL.

With CoCo's GA capabilities, data engineers and architects can deploy production-grade pipelines either conversationally with one-click temporary IAM delegation, or by generating immutable, fully auditable Terraform modules and Snowflake SQL scripts.

---

## Repository Structure

```
coco-data-loading/
├── README.md                              # Architectural overview & engineering specifications
├── CONTRIBUTING.md                        # Google-style development & contribution guidelines
├── docs/
│   ├── architecture_decision_records/
│   │   ├── ADR-001-temporary-iam-vs-iac.md # Decision on Temporary IAM vs Terraform
│   │   └── ADR-002-iceberg-load-modes.md   # Decision on Iceberg ADD_FILES_COPY vs FULL_INGEST
├── terraform/
│   ├── modules/
│   │   ├── aws_snowpipe/                  # AWS S3 -> SQS -> Storage/Notification Integration -> Snowpipe
│   │   ├── azure_snowpipe/                # ADLS Gen2 -> Event Grid -> Storage Queue -> Snowpipe
│   │   └── gcp_snowpipe/                  # GCS -> Pub/Sub -> Snowpipe
│   └── environments/
│       └── prod/                          # Production environment orchestration
├── sql/
│   ├── ddl/
│   │   ├── 01_file_formats.sql            # Performance-tuned File Formats (Vectorized/Multi-line)
│   │   ├── 02_stages.sql                  # Named External Stages & External Volumes
│   │   ├── 03_destination_tables.sql      # Standard & Snowflake-Managed Iceberg Tables
│   │   └── 04_pipes.sql                   # Auto-ingest Snowpipe DDL
│   ├── validation/
│   │   ├── pipe_monitoring.sql            # SYSTEM$PIPE_STATUS & COPY_HISTORY inspection
│   │   └── schema_evolution_audit.sql     # Schema evolution tracking & column drift checks
│   └── bulk_load/
│       └── copy_into_backfill.sql         # Idempotent bulk loading & historical backfills
└── iam/
    └── aws/
        ├── temporary_delegation_policy.json # IAM temporary setup permissions
        └── boundary_policy.json            # Snowflake IAM permissions boundary
```

---

## Architectural Patterns

### 1. Continuous Ingestion (Snowpipe Auto-Ingest)
- **Event-Driven**: Serverless ingestion triggering automatically on object creation events.
- **Zero Idle Compute**: Compute is billed strictly per-GB loaded without requiring an active virtual warehouse.
- **Automated Schema Evolution**: Tables adapt dynamically when new fields appear, eliminating pipeline breakage.

### 2. Bulk / Backfill Ingestion (COPY INTO)
- **Warehouse-Optimized**: Leverages multi-node virtual warehouse compute for one-off backfills, initial loads, and migrations.
- **Parallel Scanning**: Uses `MULTI_LINE = FALSE` for splitable file chunks.
- **Case-Insensitive Column Matching**: Automatically aligns source headers to destination schema without positional coupling.

### 3. Managed Apache Iceberg™ Ingestion
- **Storage Dual-Model**: Loads directly into Snowflake-managed Iceberg storage or external volumes.
- **Ingestion Mode Selection**:
  - `LOAD_MODE = ADD_FILES_COPY`: Zero-copy metadata registration for Parquet files authored by external Iceberg engines.
  - `LOAD_MODE = FULL_INGEST`: Native Parquet, CSV, JSON, ORC, Avro re-write into standardized Iceberg data files and metadata snapshots.

---

## Deployment Options

| Setup Option | Supported Clouds | Cloud Resource Provisioner | Optimal Use Case |
|---|---|---|---|
| **Automate Cloud Setup (Temporary Access)** | AWS (Commercial) | Snowflake (via temporary 1-hr IAM grant) | Fastest greenfield setup with no long-lived AWS keys |
| **Generate Full Terraform** | AWS, Azure, GCP | Platform / DevOps Team (via CI/CD) | GitOps-driven environments requiring immutable IaC |
| **Reuse Existing Cloud Access** | AWS, Azure, GCP | Snowflake / Platform Team | Upgrading existing stages without altering trust roles |
| **Snowflake DDL + Cloud Config Files** | AWS, Azure, GCP | Cloud Team (CloudFormation / ARM / TF) | Segregated Snowflake DBA and Cloud Admin duties |

---

## Security & Trust Boundaries

1. **No Long-Lived Access Keys**: All cloud authentication uses cross-account IAM role assumption with External IDs or workload identity federation.
2. **Permissions Boundaries**: AWS roles created through temporary access are strictly pinned to `SnowflakeStorageRoleBoundary_<version>`, preventing tag tampering and restricting access to explicitly tagged target buckets.
3. **Restricted Session Scope**: Automated CoCo executions operate under least-privilege RBAC roles without privilege escalation paths.

---

## Production Runbook & Observability

- **Pipe Health Verification**:
  ```sql
  SELECT SYSTEM$PIPE_STATUS('RAW_DB.INGEST_SCHEMA.PIPE_ORDERS_S3');
  ```
- **Load Error Tracking**:
  ```sql
  SELECT *
  FROM TABLE(INFORMATION_SCHEMA.COPY_HISTORY(
      TABLE_NAME => 'RAW_DB.INGEST_SCHEMA.ORDERS',
      START_TIME => DATEADD(hours, -24, CURRENT_TIMESTAMP())
  ))
  WHERE STATUS ILIKE '%FAILED%';
  ```

---

## References
- [Snowflake Documentation: Continuous Ingestion with CoCo](https://docs.snowflake.com/)
- [Snowflake Documentation: Bulk File Loading with CoCo](https://docs.snowflake.com/)
- [Snowflake Documentation: Apache Iceberg™ Ingestion](https://docs.snowflake.com/)
