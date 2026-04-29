# ─────────────────────────────────────────────────────────────────────────────
# Security Hub + GuardDuty
#
# RISK RATIONALE: Controls without detection are theater. Security Hub
# aggregates findings from native AWS services and maps them to compliance
# frameworks, giving you a single prioritized view of what's broken and why
# it matters. GuardDuty provides ML-based threat detection that catches
# credential abuse, cryptomining, and C2 traffic that rule-based tools miss.
#
# Together these reduce mean time to detect (MTTD) from weeks to hours.
#
# NIST SP 800-53: CA-7, IR-4, RA-5, SI-4
# ISO/IEC 27001:  A.12.6, A.16.1
# ─────────────────────────────────────────────────────────────────────────────

# ── Security Hub ──────────────────────────────────────────────────────────────

resource "aws_securityhub_account" "this" {}

# CIS AWS Foundations Benchmark — industry-standard hardening baseline
resource "aws_securityhub_standards_subscription" "cis" {
  standards_arn = "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0"
  depends_on    = [aws_securityhub_account.this]
}

# AWS Foundational Security Best Practices — AWS-curated control set
resource "aws_securityhub_standards_subscription" "aws_foundational" {
  standards_arn = "arn:aws:securityhub:${var.aws_region}::standards/aws-foundational-security-best-practices/v/1.0.0"
  depends_on    = [aws_securityhub_account.this]
}

# NIST SP 800-53 — maps findings directly to federal security controls
resource "aws_securityhub_standards_subscription" "nist" {
  standards_arn = "arn:aws:securityhub:${var.aws_region}::standards/nist-800-53/v/5.0.0"
  depends_on    = [aws_securityhub_account.this]
}

# ── GuardDuty ─────────────────────────────────────────────────────────────────
# ML-based threat detection across CloudTrail, DNS, and VPC Flow Logs.
# Detects: credential compromise, instance metadata abuse, cryptomining,
# C2 beaconing, and anomalous API call patterns.

resource "aws_guardduty_detector" "this" {
  enable = true

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = var.enable_kubernetes_protection
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = var.enable_malware_protection
        }
      }
    }
  }

  tags = var.tags
}

# ── Security Hub findings → SNS alert ────────────────────────────────────────
# Routes CRITICAL and HIGH findings to an SNS topic for alerting.
# Wire this to PagerDuty, Slack, or your SIEM of choice.

resource "aws_sns_topic" "security_findings" {
  name              = "security-hub-critical-findings"
  kms_master_key_id = "alias/aws/sns"
  tags              = var.tags
}

resource "aws_cloudwatch_event_rule" "security_hub_critical" {
  name        = "security-hub-critical-findings"
  description = "Routes Security Hub CRITICAL and HIGH findings to SNS"

  event_pattern = jsonencode({
    source      = ["aws.securityhub"]
    detail-type = ["Security Hub Findings - Imported"]
    detail = {
      findings = {
        Severity = {
          Label = ["CRITICAL", "HIGH"]
        }
        Workflow = {
          Status = ["NEW"]
        }
        RecordState = ["ACTIVE"]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "security_hub_sns" {
  rule      = aws_cloudwatch_event_rule.security_hub_critical.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.security_findings.arn
}

resource "aws_sns_topic_policy" "security_findings" {
  arn    = aws_sns_topic.security_findings.arn
  policy = data.aws_iam_policy_document.sns_eventbridge.json
}

data "aws_iam_policy_document" "sns_eventbridge" {
  statement {
    effect  = "Allow"
    actions = ["SNS:Publish"]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    resources = [aws_sns_topic.security_findings.arn]
  }
}
