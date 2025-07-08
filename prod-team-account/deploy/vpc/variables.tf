variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "cloudfence"
}

variable "vpc_id" {
  description = "The ID of the VPC where the ECS cluster will be deployed"
  type        = string
  default     = "cloudfence-vpc"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}