variable "name" {
  type = string
}

variable "secret_id" {
  type        = string
  description = "Secrets manager secret ID to rotate"
}

variable "secret_arn" {
  type        = string
  description = "Secrets manager secret ARN to rotate"
}

variable "subnet_ids" {
  type = list(string)
  description = "List of private subnet ids."
}

variable "vpc_id" {
  description = "VPC id in which the RDS instance is to be created."
  type        = string
}

variable "rotation_frequency_in_days" {
  type        = number
  description = "Specifies the number of days between automatic scheduled rotations"
  default     = 30
}

variable "tags" {
  type = map(string)
}