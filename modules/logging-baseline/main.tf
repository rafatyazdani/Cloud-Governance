# ─────────────────────────────────────────────────────────────────────────────
# Logging Baseline
#
# RISK RATIONALE: You cannot detect, investigate, or recover from incidents
# you have no record of. These controls establish the minimum audit foundation
# required for incident response, forensics, and compliance evidence.
#
# Without logs, median attacker dwell time (time to detection) extends from
# days to months. With a complete logging baseline, most cloud incidents are
# detectable within hours.
#
# NIST SP 800-53: AU-2, AU-3, AU-6, AU-9, AU-12, SI-4
# ISO/IEC 27001:  A.12.4, A.16.1
# ─────────────────────────────────────────────────────────────────────────────

# ── S3 bucket for CloudTrail logs ─────────────────────────────────────────────

resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket        = var.cloudtrail_bucket_name
  force_destroy = false

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  bucket                  = aws_s3_bucket.cloudtrail_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  policy = data.aws_iam_policy_document.cloudtrail_bucket.json
}

data "aws_iam_policy_document" "cloudtrail_bucket" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail_logs.arn]
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  # Deny non-HTTPS access to log files
  statement {
    sid    = "DenyNonHttps"
    effect = "Deny"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions   = ["s3:*"]
    resources = [
      aws_s3_bucket.cloudtrail_logs.arn,
      "${aws_s3_bucket.cloudtrail_logs.arn}/*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

# ── CloudTrail ────────────────────────────────────────────────────────────────
# Multi-region trail captures all API activity across all regions.
# Log file validation detects tampering — critical for forensic defensibility.

resource "aws_cloudtrail" "baseline" {
  name                          = var.cloudtrail_name
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true
  enable_logging                = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::"]
    }
  }

  tags = var.tags
}

# ── AWS Config ────────────────────────────────────────────────────────────────
# Records configuration state of all resources. Essential for drift detection,
# compliance evidence, and reconstructing the state of resources at any point
# in time during an incident investigation.

resource "aws_config_configuration_recorder" "baseline" {
  name     = "baseline-recorder"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "baseline" {
  name           = "baseline-delivery"
  s3_bucket_name = aws_s3_bucket.cloudtrail_logs.id
  depends_on     = [aws_config_configuration_recorder.baseline]
}

resource "aws_config_configuration_recorder_status" "baseline" {
  name       = aws_config_configuration_recorder.baseline.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.baseline]
}

resource "aws_iam_role" "config" {
  name               = "AWSConfigRole"
  assume_role_policy = data.aws_iam_policy_document.config_assume.json
  tags               = var.tags
}

data "aws_iam_policy_document" "config_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "config" {
  role       = aws_iam_role.config.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

# ── VPC Flow Logs ─────────────────────────────────────────────────────────────
# Captures network-layer telemetry for all VPCs. Required for detecting
# lateral movement, data exfiltration, and anomalous traffic patterns.

resource "aws_flow_log" "vpc" {
  for_each        = toset(var.vpc_ids)
  vpc_id          = each.value
  traffic_type    = "ALL"
  iam_role_arn    = aws_iam_role.flow_log.arn
  log_destination = aws_cloudwatch_log_group.flow_logs.arn

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/aws/vpc/flow-logs"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_iam_role" "flow_log" {
  name               = "VPCFlowLogRole"
  assume_role_policy = data.aws_iam_policy_document.flow_log_assume.json
  tags               = var.tags
}

data "aws_iam_policy_document" "flow_log_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "flow_log" {
  name = "VPCFlowLogPolicy"
  role = aws_iam_role.flow_log.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}
