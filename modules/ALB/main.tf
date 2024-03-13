resource "aws_lb" "example" {
  name               = var.alb_name
  load_balancer_type = "application"
  subnets            = var.subnets_ids
  security_groups    = var.security_groups
  enable_cross_zone_load_balancing = true
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.example.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      protocol     = "HTTPS"
      port         = "443"
      status_code  = "HTTP_301"
    }
  }
}

# module "aws_acm_certificate" {
#   source  = "../acm"
#   root_domain_name = var.root_domain_name
# }

resource "aws_acm_certificate" "example" {
  domain_name       = var.root_domain_name
  validation_method = "DNS"
  key_algorithm = "RSA_2048"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "example-api" {
  name                 = "${var.environment}-example-api"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 60
  health_check {
    enabled             = true
    path                = "/"
    interval            = 30
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
}
resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.example.arn
  certificate_arn   = aws_acm_certificate.example.arn
  port              = 443
  protocol          = "HTTPS"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "HEALTHY"
      status_code  = "200"
    }
  }
}

resource "aws_lb_listener_rule" "redirect_http_to_https" {
  listener_arn = aws_lb_listener.https_listener.arn
  priority     = 1
  

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example-api.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }

  condition {
    host_header {
      values = var.host_header
    }
  }
}