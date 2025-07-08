terraform {
  backend "s3" {
    bucket         = "cloudfence-prod-state"
    key            = "prod-team-account/deploy/acm/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "s3-prod-lock"
    encrypt        = true
  }
}