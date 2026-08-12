locals {
  state_bucket = "${var.account_alias}-${var.bucket_purpose}-${var.region}"
}

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
  bucket           = format("%s-%s-%s-%s", var.environment, var.tfstate_bucket_name, data.aws_caller_identity.current.account_id, data.aws_region.current.region)
  region           = var.region
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

data "tls_certificate" "provider" {
  url = "https://app.terraform.io"
}

resource "aws_iam_openid_connect_provider" "hcp_terraform" {
  url = "https://app.terraform.io"

  client_id_list = [
    "aws.workload.identity", # Default audience in HCP Terraform for AWS.
  ]

  thumbprint_list = [
    data.tls_certificate.provider.certificates[0].sha1_fingerprint,
  ]
}

data "aws_iam_policy_document" "terraform_oidc_assume_role_policy" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.hcp_terraform.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "app.terraform.io:aud"
      values   = ["aws.workload.identity"]
    }

    condition {
      test     = "StringLike"
      variable = "app.terraform.io:sub"
      values   = ["organization:*:project:*:workspace:*:run_phase:*"]
    }
  }
}

resource "aws_iam_role" "terraform_oidc_role" {
  name               = "terraform_oidc_role"
  assume_role_policy = data.aws_iam_policy_document.terraform_oidc_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "terraform_admin_access" {
  policy_arn = data.aws_iam_policy.admin_access.arn
  role       = aws_iam_role.terraform_oidc_role.name
}