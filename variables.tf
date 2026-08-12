variable "account_alias" {
  description = "The desired AWS account alias."
  default     = "kramarov666-tfalias"
  type        = string
}

variable "bucket_purpose" {
  description = "Name to identify the bucket's purpose"
  default     = "tf-state"
  type        = string
}

variable "enable_s3_public_access_block" {
  description = "Bool for toggling whether the s3 public access block resource should be enabled."
  type        = bool
  default     = true
}

variable "kms_master_key_id" {
  type        = string
  default     = ""
  description = "The AWS KMS master key ID used for the SSE-KMS encryption of the state bucket."
}

variable "tfstate_bucket_name" {
  description = "terraform state bucket"
  default     = "tfstate-bucket"
  type        = string
}

variable "log_retention" {
  description = "Log retention of access logs of state bucket."
  default     = 90
  type        = number
}

variable "manage_account_alias" {
  type        = bool
  default     = true
  description = "Manage the account alias as a resource. Set to 'false' if this behavior is not desired."
}

variable "region" {
  description = "AWS region."
  default     = "us-east-1"
  type        = string
}

variable "environment" {
  description = "The environment name."
  default     = "prod"
  type        = string
}