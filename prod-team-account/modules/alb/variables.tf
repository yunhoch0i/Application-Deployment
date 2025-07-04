variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "A list of public subnet IDs for the ALB"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "The ID of the security group for the ALB"
  type        = string
}