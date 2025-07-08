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

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "cloudfence-prod-state"
    key    = "prod-team-account/deploy/vpc/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

data "terraform_remote_state" "alb" {
  backend = "s3"
  config = {
    bucket = "cloudfence-prod-state"
    key    = "prod-team-account/deploy/alb/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

data "terraform_remote_state" "iam" {
  backend = "s3"
  config = {
    bucket = "cloudfence-prod-state"
    key    = "prod-team-account/deploy/iam/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

data "terraform_remote_state" "ecr" {
  backend = "s3"
  config = {
    bucket = "cloudfence-operation-state"
    key    = "operation-team-account/deploy/ecr/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

data "aws_ami" "latest_shared_ami" {
  most_recent = true
  owners      = [var.ami_owner_account_id] # operation-team-account의 AMI 
  filter {
    name   = "name"
    values = ["WHS-CloudFence-*"]
  }
}

# ECS 클러스터 생성
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.project_name}-ecs-cluster"
}

# ECS Launch Template
resource "aws_launch_template" "ecs_launch_template" {
  name_prefix   = "${var.project_name}-ecs-launch-template-"
  image_id      = data.aws_ami.latest_shared_ami.id
  instance_type = "t3.micro"

  iam_instance_profile {
    name = data.terraform_remote_state.iam.outputs.ecs_instance_profile_name
  }

  metadata_options {
    http_tokens   = "required" # 토큰 기반의 IMDSv2만 허용하도록 설정
    http_endpoint = "enabled"
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [data.terraform_remote_state.vpc.outputs.ecs_security_group_id]
  }

  user_data = base64encode(<<-EOF
        #!/bin/bash
        echo ECS_CLUSTER=${aws_ecs_cluster.ecs_cluster.name} >> /etc/ecs/ecs.config
        EOF
  )

  tags = {
    Name = "${var.project_name}-ecs-launch-template"
  }
}

# ECS Auto Scaling Group
resource "aws_autoscaling_group" "ecs_auto_scaling_group" {
  launch_template {
    id      = aws_launch_template.ecs_launch_template.id
    version = "$Latest"
  }

  min_size              = 1
  max_size              = 4
  desired_capacity      = 2
  vpc_zone_identifier   = [for subnet in data.terraform_remote_state.vpc.outputs.private_subnet_ids : subnet]
  health_check_type     = "EC2"
  force_delete          = true
  protect_from_scale_in = true

  tag {
    key                 = "ECS_Manage"
    value               = "${var.project_name}-ecs-auto-scaling-group"
    propagate_at_launch = true
  }

}

# ECS capacity provider
resource "aws_ecs_capacity_provider" "ecs_capacity_provider" {
  name = "${var.project_name}-ecs-capacity-provider"
  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs_auto_scaling_group.arn
    managed_termination_protection = "ENABLED"
    managed_scaling {
      status          = "ENABLED"
      target_capacity = 100
    }
  }
}

# Capacity provider association
resource "aws_ecs_cluster_capacity_providers" "ecs_cluster_capacity_providers" {
  cluster_name       = aws_ecs_cluster.ecs_cluster.name
  capacity_providers = [aws_ecs_capacity_provider.ecs_capacity_provider.name]
  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
    weight            = 100
    base              = 1
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "ecs_task_definition" {
  family                   = "${var.project_name}-ecs-task"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  execution_role_arn       = data.terraform_remote_state.iam.outputs.ecs_task_execution_role_arn

  container_definitions = jsonencode([
    {
      name      = "${var.project_name}-container"
      image     = "${data.terraform_remote_state.ecr.outputs.repository_url}:latest"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "ecs_service" {
  name            = "${var.project_name}-ecs-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task_definition.arn
  desired_count   = 2


  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
    weight            = 100
  }

  load_balancer {
    target_group_arn = data.terraform_remote_state.alb.outputs.blue_target_group_arn
    container_name   = "${var.project_name}-container"
    container_port   = 80
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  health_check_grace_period_seconds = 60

  tags = {
    Name = "${var.project_name}-ecs-service"
  }
}
  