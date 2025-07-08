variable "domain_name" {
  description = "The domain name for the SSL certificate"
  type        = string
  default     = "cloudfence.cloud"
}

variable "zone_id" {
  description = "The Route 53 Hosted Zone ID for the domain"
  type        = string
  default     = "Z0324594CRM7IYDEWX83"
}