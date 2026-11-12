terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# -----------------------------------------------------------------------------
# 1. GitHub OIDC Provider & IAM Role
# -----------------------------------------------------------------------------

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f8d264fcd9"
  ]
}

data "aws_iam_openid_connect_provider" "existing_github" {
  count = var.create_oidc_provider ? 0 : 1
  url   = "https://token.actions.githubusercontent.com"
}

locals {
  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : data.aws_iam_openid_connect_provider.existing_github[0].arn
}

resource "aws_iam_role" "github_actions_ssm" {
  name        = var.role_name
  description = "Role for GitHub Actions to fetch SSM parameters via OIDC"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = local.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo_owner}/*:*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "ssm_read" {
  name = "github-ssm-parameter-read"
  role = aws_iam_role.github_actions_ssm.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:*:parameter/github/${var.github_owner}/*"
      },
      {
        Effect   = "Allow"
        Action   = "kms:Decrypt"
        Resource = "*"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# 2. Shared Parameters (/github/nlkomaru/shared/*)
# -----------------------------------------------------------------------------

resource "aws_ssm_parameter" "shared" {
  for_each = var.shared_parameters

  name        = "/github/${var.github_owner}/shared/${each.key}"
  description = "Shared parameter across repositories (${each.key})"
  type        = "SecureString"
  value       = each.value
  overwrite   = true
}
