variable "aws_region" {
  type = string
}

variable "tags" {
  type = map(string)
  default = {
    "application" = "my-app"
    "automation" = "terraform"
  }
}

variable "stack_name" {
  type = string
}

############ VPC ############

variable "cidr" {
  type = string
  description = "VPC CIDR block"
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  type = list(string)
  description = "List of public subnets"
  default = [
    "10.0.16.0/20",
    "10.0.48.0/20",
    "10.0.80.0/20"
  ]
}

variable "private_subnets" {
  type = list(string)
  description = "List of private subnets"
  default = [
    "10.0.0.0/20",
    "10.0.32.0/20",
    "10.0.64.0/20"
  ]
}

variable "availability_zones" {
  type = list(string)
  description = "List of availability zones"
  default = [
    "eu-central-1a",
    "eu-central-1b",
    "eu-central-1c"
  ]
}

############ ECS ############

variable "ecs_desired_count" {
  type = number
  description = "Desired number of tasks at creation"
}

variable "ecs_min_capacity" {
  type = number
  description = "Min number of tasks"
}

variable "ecs_max_capacity" {
  type = number
  description = "Max number of tasks"
}

variable "ecs_cpu" {
  type = number
  description = "CPU value: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html"
}

variable "ecs_memory" {
  type = number
  description = "Memory value: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html"
}

variable "ecs_deployment_minimum_healthy_percent" {
  type = number
  description = "Lower limit (as a percentage of the service's desiredCount) of the number of running tasks that must remain running and healthy in a service during a deployment"
}

variable "ecs_deployment_maximum_percent" {
  type = number
  description = "Upper limit (as a percentage of the service's desiredCount) of the number of running tasks that can be running in a service during a deployment"
  default = 200
}

variable "ecs_container_port" {
  type = number
  default = 8080
}

############ ALB ############

variable "alb_health_check_path" {
  type = string
  description = "HTTP path for task health check"
  default     = "/actuator/health"
}

############ Route 53 ############

variable "domain_name" {
  type = string
  description = "Domain name to use when creating Route53 updates e.g. example.com"
}

variable "environment_domain_name" {
  type = string
  description = "Environment domain name e.g. staging.example.com"
}

############ DB ############

variable "db_port" {
  type = number
  default = 3306
}

variable "db_username" {
  type = string
  default = "admin"
}
