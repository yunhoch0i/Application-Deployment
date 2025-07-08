output "dns_name" {
  description = "The DNS name of the ALB"
  value       = aws_lb.alb.dns_name
}

output "listener_arn" {
  description = "The ARN of the ALB listener"
  value       = aws_lb_listener.https.arn
}

output "blue_target_group_name" {
  description = "The name of the blue target group"
  value       = aws_lb_target_group.blue.name
}

output "green_target_group_name" {
  description = "The name of the green target group"
  value       = aws_lb_target_group.green.name
}

output "blue_target_group_arn" {
  description = "The ARN of the blue target group"
  value       = aws_lb_target_group.blue.arn
}
