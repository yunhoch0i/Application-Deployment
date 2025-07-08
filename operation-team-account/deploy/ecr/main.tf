terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

}

provider "aws" {
  region = "ap-northeast-2"
}

data "terraform_remote_state" "iam" {
  backend = "s3"
  config = {
    bucket = "cloudfence-prod-state"
    key    = "prod-team-account/iam/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

# operation-team-account의 ECR 리포지토리 생성 및 정책 설정
data "aws_iam_policy_document" "ecr_repo_policy_document" {
  statement {
    sid    = "AllowCrossAccountPush"
    effect = "Allow"
    principals {
      type = "AWS"
      # prod 계정의 역할 ARN은 변수로 전달
      identifiers = [data.terraform_remote_state.iam.outputs.github_actions_role_arn]
    }
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:GetAuthorizationToken"
    ]
  }
}


# ECR 리포지토리 생성
resource "aws_ecr_repository" "app_ecr_repo" {
  name                 = var.project_name
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# 정책을 리포지토리에 연결
resource "aws_ecr_repository_policy" "app_ecr_repo_policy" {
  repository = aws_ecr_repository.app_ecr_repo.name
  policy     = data.aws_iam_policy_document.ecr_repo_policy_document.json
}