variable "domain_name" {
  type = string
  description = "Domain name to use when creating Route53 updates e.g. example.com"
}

variable "environment_domain_name" {
  type = string
  description = "Environment domain name e.g. staging.example.com"
}

variable "lb_dns_name" {
  type = string
  description = "Load balancer hostname"
}

variable "lb_dns_zone_id" {
  type = string
  description = "Load balancer DNS zone ID"
}

variable "tags" {
  type = map(string)
}