
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_iam_policy" "admin_access" {
  arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_kms_key" "tfstate_bucket_key" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
}

resource "aws_iam_account_alias" "alias" {
  count         = var.manage_account_alias ? 1 : 0
  account_alias = var.account_alias
}

resource "aws_s3_bucket" "tfstate_bucket" {
  bucket = format("%s-%s-%s-%s", var.environment, var.tfstate_bucket_name, data.aws_caller_identity.current.account_id, data.aws_region.current.region)
  region = var.region
}

resource "aws_s3_bucket_versioning" "tfstate_bucket" {
  bucket = aws_s3_bucket.tfstate_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate_bucket" {
  bucket = aws_s3_bucket.tfstate_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.tfstate_bucket_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    data.tls_certificate.github.certificates[0].sha1_fingerprint
  ]

  tags = {
    Name = "github-actions-oidc"
  }
}

resource "aws_iam_role" "github_actions_admin" {
  name = "terraform_oidc_role_admin"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }

      Action = "sts:AssumeRoleWithWebIdentity"

      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          #https://github.com/aws-actions/configure-aws-credentials#oidc-configuration-details
          "token.actions.githubusercontent.com:sub" = "repo:kramarov666@4160554/terraform-micro@1322623873:environment:prod"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "terraform_admin_access" {
  policy_arn = data.aws_iam_policy.admin_access.arn
  role       = aws_iam_role.github_actions_admin.name
}

resource "aws_iam_role" "github_actions_readonly" {
  name = "terraform_oidc_role_readonly"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }

      Action = "sts:AssumeRoleWithWebIdentity"

      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          #https://github.com/aws-actions/configure-aws-credentials#oidc-configuration-details
          "token.actions.githubusercontent.com:sub" = "repo:kramarov666@4160554/terraform-micro@1322623873:ref:refs/heads/edit-pipeline"
        }
      }
    }]
  })
}

resource "aws_iam_policy" "github_actions_readonly_policy" {
  name        = "terraform_oidc_policy_readonly"
  description = "This policy grants read-only access to AWS resources for GitHub Actions workflows."

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "s3:GetObject",
          "s3:ListBucket",
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_readonly_policy_attachment" {
  policy_arn = aws_iam_policy.github_actions_readonly_policy.arn
  role       = aws_iam_role.github_actions_readonly.name
}