# ISO/IEC 27001:2022 Control Mapping

This document maps each Terraform module to its corresponding ISO/IEC 27001:2022 Annex A controls.

---

## A.5 — Organizational Controls

| Control | Reference | Terraform Resource | Notes |
|---------|-----------|-------------------|-------|
| Information security policies | A.5.1 | All modules | Terraform code operationalizes policy — infrastructure cannot deviate from it. |
| Segregation of duties | A.5.3 | `aws_iam_role.security_readonly` | Separate read-only security role enforces functional separation. |
| Management of privileged access rights | A.5.18 | `aws_organizations_policy.deny_root_usage` | Root access eliminated at org level; privileged access scoped to named roles. |

---

## A.8 — Technological Controls

| Control | Reference | Terraform Resource | Notes |
|---------|-----------|-------------------|-------|
| User endpoint devices | A.8.1 | `aws_guardduty_detector` (malware protection) | EBS malware scanning extends endpoint protection to cloud workloads. |
| Privileged access rights | A.8.2 | `aws_iam_role.security_readonly` | MFA condition on assume-role enforces strong authentication for privileged paths. |
| Access control | A.8.3 | `aws_organizations_policy.deny_public_s3` | Prevents accidental public exposure of data at the account level. |
| Protection of log information | A.8.15 | `aws_organizations_policy.deny_cloudtrail_disable`, `aws_s3_bucket_server_side_encryption_configuration` | Logs encrypted at rest, protected by SCP from deletion or modification. |
| Monitoring activities | A.8.16 | `aws_cloudtrail.baseline`, `aws_flow_log.vpc`, `aws_guardduty_detector` | Multi-layer monitoring: API (CloudTrail), network (Flow Logs), anomaly (GuardDuty). |
| Management of technical vulnerabilities | A.8.8 | `aws_securityhub_standards_subscription.*` | Continuous misconfiguration scanning against CIS and AWS Foundational benchmarks. |
| Configuration management | A.8.9 | `aws_config_configuration_recorder` | AWS Config records all resource configuration changes with full history. |
| Information deletion | A.8.10 | `aws_s3_bucket_versioning` | Versioning on log buckets prevents accidental deletion of audit records. |
| Data masking | A.8.11 | `aws_s3_bucket_server_side_encryption_configuration` | KMS encryption at rest for all log data. |
| Prevention of data leakage | A.8.12 | `aws_organizations_policy.deny_public_s3` | Account-level block prevents data leakage via misconfigured S3 buckets. |
| Monitoring and anomaly detection | A.8.16 | `aws_cloudwatch_event_rule.security_hub_critical` | Automated alerting on CRITICAL/HIGH findings reduces detection-to-response gap. |

---

## A.9 — Physical and Environmental Security

*Not applicable — cloud-native controls. Physical security is the responsibility of AWS (shared responsibility model).*

---

## Shared Responsibility Notes

These controls operate entirely within the **customer responsibility** layer of the AWS Shared Responsibility Model:

- AWS is responsible for: physical infrastructure, hypervisor, managed service availability
- Customer is responsible for: IAM configuration, logging enablement, data classification, application security

This module addresses the most commonly misconfigured customer-responsibility controls — the ones that appear in the majority of cloud breach post-mortems.
