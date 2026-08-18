output "state_bucket" {
  description = "The state_bucket name"
  value       = aws_s3_bucket.tfstate_bucket.id
}

output "iam_role_arn_admin" {
  description = "The ARN of the IAM Admin role"
  value       = aws_iam_role.github_actions_admin.arn
}

output "iam_role_arn_readonly" {
  description = "The ARN of the IAM ReadOnly role"
  value       = aws_iam_role.github_actions_readonly.arn
}