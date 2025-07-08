variable "project_name" {
  description = "The name of the project for resource naming"
  type        = string
  default     = "cloudfence"
}

variable "ami_owner_account_id" {
  description = "The AWS Account ID of the account that owns the shared AMI"
  type        = string
  default     = "502676416967" # operation-team-account
}