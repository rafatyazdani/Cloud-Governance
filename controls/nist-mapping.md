# NIST SP 800-53 Control Mapping

This document maps each Terraform resource in the toolkit to its corresponding NIST SP 800-53 Rev 5 controls, with rationale for why the control reduces risk — not just satisfies a requirement.

---

## AC — Access Control

| Control | ID | Terraform Resource | Risk Rationale |
|---------|----|--------------------|----------------|
| Account Management | AC-2 | `aws_iam_account_password_policy` | Enforces lifecycle controls on credentials. Expired and reused passwords are a primary vector for credential-based attacks. |
| Access Enforcement | AC-3 | `aws_organizations_policy.deny_root_usage` | Root credentials bypass all IAM policy controls. Denying root usage eliminates the highest-privilege attack path. |
| Least Privilege | AC-6 | `aws_iam_role.security_readonly` | Scoped assume-role with MFA condition enforces need-to-know access. Reduces blast radius of any single credential compromise. |

---

## AU — Audit and Accountability

| Control | ID | Terraform Resource | Risk Rationale |
|---------|----|--------------------|----------------|
| Auditable Events | AU-2 | `aws_cloudtrail.baseline` | Multi-region trail captures all API calls. Without this, attackers can operate undetected for months. |
| Content of Audit Records | AU-3 | `aws_cloudtrail.baseline` | CloudTrail records who, what, when, and from where — the minimum required for forensic reconstruction. |
| Audit Review / Analysis | AU-6 | `aws_securityhub_account` | Security Hub aggregates and prioritizes findings, making audit data actionable rather than just stored. |
| Protection of Audit Information | AU-9 | `aws_organizations_policy.deny_cloudtrail_disable` | SCP-level protection prevents even admins from disabling or deleting logs — preserving forensic integrity. |
| Audit Record Generation | AU-12 | `aws_config_configuration_recorder` | Config records resource-level state changes continuously, complementing CloudTrail's API-level logging. |

---

## CA — Assessment, Authorization, and Monitoring

| Control | ID | Terraform Resource | Risk Rationale |
|---------|----|--------------------|----------------|
| Continuous Monitoring | CA-7 | `aws_guardduty_detector`, `aws_securityhub_account` | Automated continuous monitoring reduces MTTD from weeks to hours. Manual review alone cannot match the volume of cloud events. |

---

## IA — Identification and Authentication

| Control | ID | Terraform Resource | Risk Rationale |
|---------|----|--------------------|----------------|
| Authenticator Management | IA-5 | `aws_iam_account_password_policy` | Password complexity and history requirements reduce credential guessing and stuffing attack success rates. |
| MFA Enforcement | IA-8 | `aws_iam_role.security_readonly` (assume-role condition) | MFA on role assumption means stolen static credentials alone are insufficient for privileged access. |

---

## IR — Incident Response

| Control | ID | Terraform Resource | Risk Rationale |
|---------|----|--------------------|----------------|
| Incident Handling | IR-4 | `aws_cloudwatch_event_rule.security_hub_critical` | Automated routing of CRITICAL/HIGH findings to SNS reduces triage time. Without this, findings sit in a dashboard until someone checks it. |

---

## RA — Risk Assessment

| Control | ID | Terraform Resource | Risk Rationale |
|---------|----|--------------------|----------------|
| Vulnerability Monitoring | RA-5 | `aws_securityhub_standards_subscription.*` | CIS, AWS Foundational, and NIST standards subscriptions provide continuous misconfiguration detection against known-bad patterns. |

---

## SI — System and Information Integrity

| Control | ID | Terraform Resource | Risk Rationale |
|---------|----|--------------------|----------------|
| Information System Monitoring | SI-4 | `aws_guardduty_detector`, `aws_flow_log.vpc` | Network-layer telemetry (flow logs) + ML-based anomaly detection (GuardDuty) together cover the detection gap that signature-based tools leave open. |
