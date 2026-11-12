variable "aws_region" {
  type        = string
  description = "AWS Region to create resources and store SSM parameters"
  default     = "ap-northeast-1"
}

variable "github_owner" {
  type        = string
  description = "GitHub username or organization name"
  default     = "nlkomaru"
}

variable "role_name" {
  type        = string
  description = "IAM Role name for GitHub Actions"
  default     = "github-actions-ssm-role"
}

variable "create_oidc_provider" {
  type        = bool
  description = "Set to true if GitHub Actions OIDC provider does not exist yet in AWS account"
  default     = false
}

variable "shared_parameters" {
  type        = map(string)
  description = "Shared secrets (name => value) for /github/nlkomaru/shared/* (saved as SecureString)"
  default     = {}
}
