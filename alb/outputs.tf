output "aws_alb_target_group_arn" {
  value = aws_alb_target_group.this.arn
}

output "aws_alb_dns_name" {
  value = aws_alb.this.dns_name
}

output "aws_alb_zone_id" {
  value = aws_alb.this.zone_id
}
