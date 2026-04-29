terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = "security"
  }
}

module "iam_guardrails" {
  source = "../../modules/iam-guardrails"

  trusted_account_arns = var.trusted_account_arns
  tags                 = local.tags
}

module "logging_baseline" {
  source = "../../modules/logging-baseline"

  cloudtrail_bucket_name = "${var.environment}-cloudtrail-logs-${var.aws_account_id}"
  vpc_ids                = var.vpc_ids
  log_retention_days     = 365
  tags                   = local.tags
}

module "security_hub" {
  source = "../../modules/security-hub"

  aws_region  = var.aws_region
  alert_email = var.alert_email
  tags        = local.tags
}
