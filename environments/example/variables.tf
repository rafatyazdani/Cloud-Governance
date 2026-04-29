variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "AWS account ID (used for unique bucket naming)"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. prod, staging)"
  type        = string
  default     = "prod"
}

variable "trusted_account_arns" {
  description = "ARNs of accounts/roles that can assume the security read-only role"
  type        = list(string)
  default     = []
}

variable "vpc_ids" {
  description = "List of VPC IDs to enable flow logs on"
  type        = list(string)
  default     = []
}

variable "alert_email" {
  description = "Email for critical security finding alerts"
  type        = string
  default     = ""
}
