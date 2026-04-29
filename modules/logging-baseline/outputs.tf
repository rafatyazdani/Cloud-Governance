output "cloudtrail_bucket_arn" {
  description = "ARN of the CloudTrail S3 bucket"
  value       = aws_s3_bucket.cloudtrail_logs.arn
}

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail trail"
  value       = aws_cloudtrail.baseline.arn
}

output "flow_log_group_name" {
  description = "Name of the VPC flow logs CloudWatch log group"
  value       = aws_cloudwatch_log_group.flow_logs.name
}
