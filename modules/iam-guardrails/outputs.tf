output "security_readonly_role_arn" {
  description = "ARN of the security read-only IAM role"
  value       = aws_iam_role.security_readonly.arn
}

output "deny_root_policy_id" {
  description = "ID of the DenyRootUsage SCP"
  value       = aws_organizations_policy.deny_root_usage.id
}
