variable "aws_region" {
  type = string
}

variable "stack_name" {
  type = string
}

variable "cidr" {
  type = string
  description = "VPC CIDR block"
}

variable "public_subnets" {
  type = list(string)
  description = "List of public subnets"
}

variable "private_subnets" {
  type = list(string)
  description = "List of private subnets"
}

variable "enable_nat_gateway" {
  type = bool
  description = "Enable NAT gateway for private subnets"
  default = true
}

variable "availability_zones" {
  type = list(string)
  description = "List of availability zones"
}

variable "security_group_ecs_task" {
  type = string
}

variable "tags" {
  type = map(string)
}