resource "aws_alb" "this" {
  name = var.stack_name
  internal = false
  load_balancer_type = "application"
  security_groups = var.alb_security_groups
  subnets = var.subnets.*.id

  enable_deletion_protection = false

  tags = var.tags
}

resource "aws_alb_target_group" "this" {
  name = "${var.stack_name}-tg"
  port = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = var.health_check_path
    unhealthy_threshold = "2"
  }

  tags = var.tags
}

# Redirect to https listener
resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_alb.this.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Redirect traffic to target group
resource "aws_alb_listener" "https" {
  load_balancer_arn = aws_alb.this.id
  port              = 443
  protocol          = "HTTPS"

  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.alb_tls_cert_arn

  default_action {
    target_group_arn = aws_alb_target_group.this.id
    type             = "forward"
  }
}