# VPC의 ID

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.vpc.id # network.tf 파일에 정의된 aws_vpc 리소스의 id 값
}

# Public Subnet들의 ID 목록을 출력
output "public_subnet_ids" {
  description = "A list of public subnet IDs"
  # network.tf 파일에 정의된 public 서브넷 리소스들의 id를 리스트로 묶어서 출력
  value = [aws_subnet.public1.id, aws_subnet.public2.id]
}

# Private Subnet들의 ID 목록을 출력
output "private_subnet_ids" {
  description = "A list of private subnet IDs"
  value       = [aws_subnet.private1.id, aws_subnet.private2.id]
}

# ALB용 security group의 이름을 출력
output "alb_security_group_id" {
  description = "The ID of the security group for the ALB"
  value       = aws_security_group.alb_sg.id # security_group.tf 파일에 정의된 보안 그룹의 id
}

# ECS용 보안 그룹의 ID를 출력

output "ecs_security_group_id" {
  description = "The ID of the security group for the ECS tasks"
  value       = aws_security_group.ecs_sg.id # security_group.tf 파일에 정의된 보안 그룹의 id
}