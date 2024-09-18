variable "name" {
  type = string
}

variable "vpc_security_group_ids" {
  type = list(string)
}

variable "subnet_ids" {
  type = list(string)
}

variable "tags" {
  type = map(string)
}

variable "min_capacity" {
  type    = number
  default = 0.5
}

variable "max_capacity" {
  type    = number
  default = 1.0
}

variable "nb_instances" {
  type    = number
  default = 1
}

variable "availability_zones" {
  type = list(string)
  description = "List of availability zones"
}

variable "db_username" {
  type = string
  default = "admin"
}
