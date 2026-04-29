# Threat Model

This document maps real-world attack scenarios to the controls in this toolkit — showing which controls prevent an attack, which detect it, and what residual risk remains.

The goal is not to enumerate every possible threat. It is to demonstrate that every control in this repo exists because of a specific attacker behavior, not because a framework checkbox required it.

---

## Attack Scenarios

### 1. Credential Theft — IAM Key Compromise

**Attack path:**
An attacker obtains a long-lived IAM access key (via exposed `.env` file, GitHub leak, phishing, or insider threat) and uses it to enumerate resources, escalate privileges, and exfiltrate data.

**This is the most common cloud breach pattern.** Long-lived static credentials with excessive permissions are the root cause in the majority of AWS incidents.

| Stage | Control | How It Helps |
|-------|---------|--------------|
| Prevent | `aws_iam_account_password_policy` | Forces regular rotation; prevents reuse |
| Prevent | `aws_iam_role.security_readonly` | MFA condition on assume-role blocks static key alone |
| Detect | `aws_cloudtrail.baseline` | Logs all API calls from the compromised key |
| Detect | `aws_guardduty_detector` | Flags anomalous usage — unusual region, new IP, reconnaissance pattern |
| Detect | `aws_securityhub_account` | Surfaces IAM findings (unused credentials, no MFA) proactively |
| Alert | `aws_cloudwatch_event_rule.security_hub_critical` | Pages on-call if GuardDuty flags credential abuse |

**Residual risk:** Static access keys not rotated by users outside this policy scope. Mitigate with AWS IAM Access Analyzer and key rotation enforcement via Config rules.

---

### 2. Insider Threat — Admin Disables Logging

**Attack path:**
A malicious or compromised admin disables CloudTrail or GuardDuty to operate without audit trail, then exfiltrates data or makes destructive changes with no forensic record.

**This is the first action taken by sophisticated attackers after gaining admin access.** If they can silence the logs, they can operate indefinitely.

| Stage | Control | How It Helps |
|-------|---------|--------------|
| Prevent | `aws_organizations_policy.deny_cloudtrail_disable` | SCP-level block — no principal, including root, can stop logging |
| Prevent | `aws_organizations_policy.deny_root_usage` | Eliminates the one identity that could otherwise override SCPs |
| Detect | `aws_cloudtrail.baseline` (log file validation) | Cryptographic validation detects if log files are tampered with after the fact |
| Detect | `aws_config_configuration_recorder` | Records if GuardDuty or Security Hub is disabled |
| Alert | `aws_cloudwatch_event_rule.security_hub_critical` | Security Hub flags GuardDuty/CloudTrail disablement as CRITICAL |

**Residual risk:** SCP attachment must be maintained at the org root or correct OUs. Gaps in SCP coverage leave individual accounts unprotected.

---

### 3. Data Exfiltration — S3 Public Exposure

**Attack path:**
A developer misconfigures an S3 bucket ACL or bucket policy, accidentally exposing sensitive data to the internet. Attacker discovers it via bucket enumeration tools (GrayhatWarfare, Bucket Finder) and exfiltrates without authentication.

**S3 misconfiguration is responsible for a disproportionate share of cloud data breaches.** The attack requires no credentials — just an open bucket and a scanner.

| Stage | Control | How It Helps |
|-------|---------|--------------|
| Prevent | `aws_organizations_policy.deny_public_s3` | Account-level public access block cannot be disabled by any user |
| Prevent | `aws_s3_bucket_public_access_block.cloudtrail_logs` | Log bucket itself explicitly blocked from public access |
| Detect | `aws_securityhub_standards_subscription.aws_foundational` | Flags any bucket missing public access block as a finding |
| Detect | `aws_cloudtrail.baseline` (data events) | Logs all S3 object-level reads — anomalous GET volume indicates exfiltration |
| Detect | `aws_guardduty_detector` (S3 protection) | Flags unusual S3 access patterns and public policy changes |

**Residual risk:** Buckets created before the SCP was applied may retain existing public access settings. Audit with `aws s3api list-buckets` + Config rule `s3-bucket-public-read-prohibited`.

---

### 4. Lateral Movement — Compromised EC2 Instance

**Attack path:**
An attacker exploits a vulnerability in an internet-facing EC2 instance, gains a shell, then uses the instance's IAM role or instance metadata service (IMDS) to pivot to other AWS services and move laterally across the environment.

| Stage | Control | How It Helps |
|-------|---------|--------------|
| Detect | `aws_flow_log.vpc` | Network telemetry shows unexpected outbound connections and east-west traffic |
| Detect | `aws_guardduty_detector` | Flags EC2 instances calling unusual APIs, connecting to known malicious IPs, or exhibiting cryptomining behavior |
| Detect | `aws_cloudtrail.baseline` | Records all API calls made by the instance role — reconnaissance actions are visible |
| Alert | `aws_cloudwatch_event_rule.security_hub_critical` | GuardDuty findings for EC2 compromise route to SNS immediately |

**Residual risk:** IMDSv1 enabled on EC2 instances allows SSRF-based metadata theft. Mitigate by enforcing IMDSv2 via a Config rule or SCP (`ec2:ModifyInstanceMetadataOptions`).

---

### 5. Ransomware — Destructive Account Takeover

**Attack path:**
Attacker with admin credentials deletes S3 buckets, terminates EC2 instances, and removes RDS snapshots, then demands ransom for restoration. Often follows credential theft and a dwell period.

| Stage | Control | How It Helps |
|-------|---------|--------------|
| Prevent | `aws_s3_bucket_versioning` | Versioned log buckets cannot be permanently deleted in a single operation |
| Prevent | `aws_organizations_policy.deny_leave_org` | Account cannot be removed from org to escape governance controls during attack |
| Detect | `aws_cloudtrail.baseline` | Mass delete/terminate API calls are immediately visible |
| Detect | `aws_guardduty_detector` | Flags anomalous destructive API call patterns |
| Alert | `aws_cloudwatch_event_rule.security_hub_critical` | High-severity findings trigger immediate paging |
| Recover | `aws_config_configuration_recorder` | Full resource configuration history enables reconstruction of pre-attack state |

**Residual risk:** S3 MFA Delete not enabled on log buckets (requires root, which is blocked by SCP — tradeoff). Versioning alone provides meaningful protection. For critical data buckets, enable Object Lock (WORM).

---

## Coverage Summary

| Threat | Prevented | Detected | Alert | Gap |
|--------|-----------|----------|-------|-----|
| Credential theft | Partial | Yes | Yes | Static key rotation not enforced |
| Admin disables logging | Yes (SCP) | Yes | Yes | SCP scope must cover all OUs |
| S3 public exposure | Yes | Yes | Yes | Pre-existing buckets need audit |
| Lateral movement (EC2) | No | Yes | Yes | IMDSv2 not enforced by this module |
| Ransomware | Partial | Yes | Yes | Object Lock not enabled |

---

## What This Toolkit Does Not Cover

- **Application-layer threats** (SQLi, XSS, SSRF) — requires WAF, code review, SAST
- **Supply chain attacks** — requires dependency scanning, artifact signing
- **Kubernetes / container security** — requires separate controls (OPA, Falco, image scanning)
- **DDoS** — requires AWS Shield Advanced
- **Social engineering / phishing** — requires MFA enforcement at IdP level, security awareness training

These are out of scope by design. This toolkit focuses on the cloud infrastructure governance layer — the foundation everything else sits on.
