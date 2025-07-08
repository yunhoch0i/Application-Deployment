output "application_name" {
  description = "The name of the CodeDeploy application"
  value       = aws_codedeploy_app.ecs_app.name
}

output "deployment_group_name" {
  description = "The name of the CodeDeploy deployment group"
  value       = aws_codedeploy_deployment_group.ecs_deployment_group.deployment_group_name
}