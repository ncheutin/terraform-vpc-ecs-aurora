data "aws_route53_zone" "this" {
  name = var.domain_name
}

resource "aws_route53_record" "this" {
  name   = var.environment_domain_name
  type = "A"
  zone_id = data.aws_route53_zone.this.zone_id

  alias {
    evaluate_target_health = true
    name                   = var.lb_dns_name
    zone_id                = var.lb_dns_zone_id
  }
}
