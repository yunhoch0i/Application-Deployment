output "repository_url" {
  description = "The URL of the ECR repository"
  value       = aws_ecr_repository.app_ecr_repo.repository_url
}