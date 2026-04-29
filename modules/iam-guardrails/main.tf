# ─────────────────────────────────────────────────────────────────────────────
# IAM Guardrails
#
# RISK RATIONALE: Misconfigured IAM is the leading cause of cloud breaches.
# These controls enforce least privilege, prevent credential abuse, and block
# the most common attacker paths — root compromise and MFA bypass.
#
# NIST SP 800-53: AC-2, AC-3, AC-6, IA-5, IA-8
# ISO/IEC 27001:  A.9.2, A.9.4
# ─────────────────────────────────────────────────────────────────────────────

# ── Account password policy ───────────────────────────────────────────────────
# Reduces credential-based attack surface. Minimum 14 chars + complexity
# prevents brute-force and credential stuffing at no cost.

resource "aws_iam_account_password_policy" "baseline" {
  minimum_password_length        = 14
  require_uppercase_characters   = true
  require_lowercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  allow_users_to_change_password = true
  max_password_age               = 90
  password_reuse_prevention      = 12
  hard_expiry                    = false
}

# ── SCP: Deny root account usage ─────────────────────────────────────────────
# Root credentials cannot be scoped or constrained by IAM policies.
# Denying root usage forces all activity through auditable IAM identities.

resource "aws_organizations_policy" "deny_root_usage" {
  name        = "DenyRootUsage"
  description = "Prevents use of the root account for any action."
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyRootActions"
        Effect   = "Deny"
        Action   = "*"
        Resource = "*"
        Condition = {
          StringLike = {
            "aws:PrincipalArn" = "arn:aws:iam::*:root"
          }
        }
      }
    ]
  })
}

# ── SCP: Deny disabling CloudTrail ────────────────────────────────────────────
# Attackers commonly disable logging immediately after gaining access.
# This SCP makes it impossible to disable audit trails, even with admin creds.

resource "aws_organizations_policy" "deny_cloudtrail_disable" {
  name        = "DenyCloudTrailDisable"
  description = "Prevents disabling or deleting CloudTrail to preserve audit integrity."
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyCloudTrailModification"
        Effect = "Deny"
        Action = [
          "cloudtrail:StopLogging",
          "cloudtrail:DeleteTrail",
          "cloudtrail:UpdateTrail"
        ]
        Resource = "*"
      }
    ]
  })
}

# ── SCP: Deny public S3 buckets ───────────────────────────────────────────────
# Public S3 misconfiguration is responsible for a significant share of cloud
# data breaches. This SCP enforces account-level block at the org layer,
# preventing any individual bucket from overriding public access settings.

resource "aws_organizations_policy" "deny_public_s3" {
  name        = "DenyPublicS3"
  description = "Prevents disabling S3 account-level public access block."
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyS3PublicAccessDisable"
        Effect = "Deny"
        Action = [
          "s3:PutAccountPublicAccessBlock"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "s3:PublicAccessBlockConfiguration/BlockPublicAcls"       = "false"
            "s3:PublicAccessBlockConfiguration/IgnorePublicAcls"      = "false"
            "s3:PublicAccessBlockConfiguration/BlockPublicPolicy"     = "false"
            "s3:PublicAccessBlockConfiguration/RestrictPublicBuckets" = "false"
          }
        }
      }
    ]
  })
}

# ── SCP: Deny leaving the AWS Organization ────────────────────────────────────
# Prevents a compromised or rogue account from removing itself from
# centralized governance controls (SCPs, Config, Security Hub).

resource "aws_organizations_policy" "deny_leave_org" {
  name        = "DenyLeaveOrganization"
  description = "Prevents member accounts from removing themselves from the organization."
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyLeaveOrg"
        Effect   = "Deny"
        Action   = ["organizations:LeaveOrganization"]
        Resource = "*"
      }
    ]
  })
}

# ── Least-privilege example role ──────────────────────────────────────────────
# Demonstrates scoped assume-role pattern. In production, replace the
# policy ARN with a custom policy scoped to exactly required permissions.

resource "aws_iam_role" "security_readonly" {
  name               = var.readonly_role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = var.tags
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = var.trusted_account_arns
    }
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "security_readonly" {
  role       = aws_iam_role.security_readonly.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}
