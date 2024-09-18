resource "aws_acm_certificate" "this" {
  domain_name = var.environment_domain_name
  validation_method = "DNS"

  validation_option {
    domain_name       = var.environment_domain_name
    validation_domain = var.domain_name
  }

  tags = var.tags
}

resource "aws_route53_record" "dns_validation_record" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name    = each.value.name
  type    = each.value.type
  zone_id = var.hosted_zone_id
  records = [each.value.record]
  ttl = 60
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in aws_route53_record.dns_validation_record : record.fqdn]
}