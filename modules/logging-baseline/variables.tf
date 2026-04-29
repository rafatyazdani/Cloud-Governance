variable "cloudtrail_bucket_name" {
  description = "Name of the S3 bucket for CloudTrail logs"
  type        = string
}

variable "cloudtrail_name" {
  description = "Name of the CloudTrail trail"
  type        = string
  default     = "baseline-trail"
}

variable "vpc_ids" {
  description = "List of VPC IDs to enable flow logs on"
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 365
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
