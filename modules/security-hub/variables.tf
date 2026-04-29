variable "aws_region" {
  description = "AWS region where Security Hub is deployed"
  type        = string
}

variable "enable_kubernetes_protection" {
  description = "Enable GuardDuty Kubernetes audit log monitoring"
  type        = bool
  default     = false
}

variable "enable_malware_protection" {
  description = "Enable GuardDuty malware protection for EC2 EBS volumes"
  type        = bool
  default     = false
}

variable "alert_email" {
  description = "Email address to receive critical security findings"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
