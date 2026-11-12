output "role_arn" {
  description = "IAM Role ARN for GitHub Actions"
  value       = aws_iam_role.github_actions_ssm.arn
}

output "shared_parameters_paths" {
  description = "List of shared SSM parameter paths created"
  value       = [for k, v in aws_ssm_parameter.shared : v.name]
}
