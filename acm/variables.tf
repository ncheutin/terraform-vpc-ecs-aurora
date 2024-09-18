variable "domain_name" {
  type = string
  description = "Domain name to use when creating Route53 updates e.g. example.com"
}

variable "environment_domain_name" {
  type = string
  description = "Environment domain name e.g. staging.example.com"
}

variable "tags" {
  type = map(string)
}

variable "hosted_zone_id" {
  type = string
}
