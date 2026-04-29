output "guardduty_detector_id" {
  description = "ID of the GuardDuty detector"
  value       = aws_guardduty_detector.this.id
}

output "security_findings_topic_arn" {
  description = "ARN of the SNS topic for critical security findings"
  value       = aws_sns_topic.security_findings.arn
}
