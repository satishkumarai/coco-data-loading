# Contributing to Snowflake CoCo Data Loading

## Code Style & Guidelines

This repository follows Google's engineering and documentation standards:
- **Hermetic & Modular**: All Terraform modules and SQL scripts are strictly isolated and reusable.
- **Explicit Naming**: All Snowflake database objects must be fully qualified (`DATABASE.SCHEMA.OBJECT`).
- **No Hardcoded Secrets**: Cloud ARNs, sensitive IDs, and tenant credentials must always be parameterized.
- **Idempotence**: SQL scripts must use `CREATE OR REPLACE` or `IF NOT EXISTS` patterns with deterministic state.

## Contribution Workflow

1. Fork or branch from `main`.
2. Ensure SQL scripts format uppercase keywords and maintain 2-space indentation.
3. Validate Terraform syntax via `terraform fmt -check` and `terraform validate`.
4. Submit PR with detailed architecture justifications and test plans.
