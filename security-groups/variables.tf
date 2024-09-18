variable "stack_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "vpc_id" {
  type = string
}

variable "container_port" {
  description = "Ingres and egress port of the container"
}

variable "public_subnet_cidr_blocks" {
  description = "Public subnet CIDR blocks"
  type = list(string)
}
