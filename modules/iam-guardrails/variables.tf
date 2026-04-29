variable "readonly_role_name" {
  description = "Name for the security read-only IAM role"
  type        = string
  default     = "SecurityReadOnly"
}

variable "trusted_account_arns" {
  description = "List of ARNs allowed to assume the security read-only role"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
