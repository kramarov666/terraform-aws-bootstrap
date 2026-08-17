output "state_bucket" {
  description = "The state_bucket name"
  value       = aws_s3_bucket.tfstate_bucket.id
}

output "iam_policy_arn" {
  description = "The ARN of the IAM policy"
  value       = aws_iam_role.terraform_oidc_role.arn
}