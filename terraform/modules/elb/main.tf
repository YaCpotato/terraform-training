#--------------------------------------------------
# elb
#--------------------------------------------------

# target group
resource "aws_lb_target_group" "ec2" {
  name     = "${var.project}-${var.environment}-tg-ec2"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    protocol            = "HTTP"
    path                = "/"
    port                = "80"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 100
    matcher             = 200
  }

  tags = {
    Name        = "${var.project}-${var.environment}-tg-ec2"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_lb_target_group_attachment" "ec2" {
  target_group_arn = aws_lb_target_group.ec2.arn
  target_id        = var.target_id
  port             = 80
}

# application load balancer
resource "aws_lb" "this" {
  name                       = "${var.project}-${var.environment}-alb"
  load_balancer_type         = "application"
  internal                   = false
  idle_timeout               = 60
  enable_deletion_protection = var.deletion_protection

  subnets         = var.subnet_ids
  security_groups = var.security_group_ids

  tags = {
    Name        = "${var.project}-${var.environment}-alb"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_route53_record" "elb" {
  zone_id = var.route53_zone_id
  name    = var.route53_name

  type = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}

# http listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = {
    Name        = "${var.project}-${var.environment}-listener-http"
    Environment = var.environment
    Project     = var.project
  }
}

# https listener
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = var.certificate_arn
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  default_action {
    target_group_arn = aws_lb_target_group.ec2.arn
    type             = "forward"
  }

  tags = {
    Name        = "${var.project}-${var.environment}-listener-https"
    Environment = var.environment
    Project     = var.project
  }
}
