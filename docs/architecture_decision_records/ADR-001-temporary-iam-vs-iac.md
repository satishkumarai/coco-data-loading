# ADR-001: Temporary IAM Delegation vs. Immutable Infrastructure-as-Code

## Status
Accepted

## Context
Deploying continuous ingestion pipelines (Snowpipe) requires establishing cloud storage access, event notifications, and Snowflake metadata objects. Snowflake Cortex Code (CoCo) offers four deployment strategies:
1. Automated cloud setup via temporary IAM delegation (AWS).
2. Complete Infrastructure-as-Code (Terraform) for cloud and Snowflake.
3. Reuse of existing storage/notification integrations.
4. Snowflake DDL generation paired with standalone cloud deployment templates (CloudFormation/ARM/Terraform).

## Decision
- For rapid prototyping, sandboxes, and developer workspaces on AWS, recommend **Automated Cloud Setup with Temporary Access**. This eliminates long-lived access keys and simplifies IAM trust configuration via time-bounded 1-hour delegation.
- For enterprise production workloads subject to SOC2, SOX, and strict GitOps change controls, mandate **Complete Terraform (IaC)**. This guarantees drift detection, immutable version control, and multi-cloud consistency across AWS, Azure, and GCP.

## Consequences
- Temporary IAM access cannot be used in AWS GovCloud or China regions.
- Terraform modules must maintain state and handle Snowflake-to-Cloud ARN dependency handshakes cleanly.
