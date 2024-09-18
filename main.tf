terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  cloud {
    organization = "YOUR-ORGANIZATION-IN-TERRAFORM-CLOUD"
    workspaces {
      name = "WORKSPACE-NAME-IN-TERRAFORM-CLOUD"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

module "vpc" {
  source                  = "./vpc"
  availability_zones      = var.availability_zones
  cidr                    = var.cidr
  private_subnets         = var.private_subnets
  public_subnets          = var.public_subnets
  stack_name              = var.stack_name
  tags                    = var.tags
  aws_region              = var.aws_region
  security_group_ecs_task = module.security_groups.ecs_tasks_sg_id
}

module "ecr" {
  source     = "./ecr"
  stack_name = var.stack_name
  tags       = var.tags
}

module "security_groups" {
  source                    = "./security-groups"
  container_port            = var.ecs_container_port
  stack_name                = var.stack_name
  tags                      = var.tags
  vpc_id                    = module.vpc.id
  public_subnet_cidr_blocks = var.public_subnets
}

module "acm" {
  source                  = "./acm"
  environment_domain_name = var.environment_domain_name
  hosted_zone_id          = module.route53.hosted_zone_id
  tags                    = var.tags
  domain_name             = var.domain_name
}

module "alb" {
  source            = "./alb"
  alb_security_groups = [module.security_groups.alb_sg_id]
  alb_tls_cert_arn  = module.acm.certificate_arn
  health_check_path = var.alb_health_check_path
  stack_name        = var.stack_name
  subnets           = module.vpc.public_subnets
  tags              = var.tags
  vpc_id            = module.vpc.id
}

module "route53" {
  source                  = "./route53"
  domain_name             = var.domain_name
  environment_domain_name = var.domain_name
  lb_dns_name             = module.alb.aws_alb_dns_name
  lb_dns_zone_id          = module.alb.aws_alb_zone_id
  tags                    = var.tags
}

module "aurora" {
  source             = "./aurora"
  name               = var.stack_name
  subnet_ids         = module.vpc.private_subnets.*.id
  vpc_security_group_ids = [module.security_groups.db_sg_id]
  db_username        = var.db_username
  availability_zones = var.availability_zones
  tags               = var.tags
}

module "db_secret_rotation_lambda" {
  source     = "./lambdas/db_secret_rotation"
  name       = var.stack_name
  subnet_ids = module.vpc.private_subnets.*.id
  vpc_id     = module.vpc.id
  secret_id  = module.aurora.secret_id
  secret_arn = module.aurora.secret_arn
  tags       = var.tags
}

module "ecs" {
  source                             = "./ecs"
  aws_alb_target_group_arn           = module.alb.aws_alb_target_group_arn
  container_port                     = var.ecs_container_port
  container_secrets = []
  container_secrets_arns             = ""
  cpu                                = var.ecs_cpu
  deployment_minimum_healthy_percent = var.ecs_deployment_minimum_healthy_percent
  desired_count                      = var.ecs_desired_count
  ecs_service_security_groups = [module.security_groups.ecs_tasks_sg_id]
  max_capacity                       = var.ecs_max_capacity
  memory                             = var.ecs_memory
  min_capacity                       = var.ecs_min_capacity
  stack_name                         = var.stack_name
  subnets                            = module.vpc.private_subnets
  tags                               = var.tags
  container_image                    = module.ecr.aws_ecr_repository_url
  aws_account_id                     = data.aws_caller_identity.current.account_id
  aws_region                         = var.aws_region
  db_port                            = var.db_port
}

module "app-ci" {
  source                      = "./app-ci"
  repository_arn              = module.ecr.aws_ecr_repository_arn
  ecs_service_arn             = module.ecs.service_arn
  ecs_task_execution_role_arn = module.ecs.task_execution_role_arn
  ecs_task_role_arn           = module.ecs.task_role_arn
}