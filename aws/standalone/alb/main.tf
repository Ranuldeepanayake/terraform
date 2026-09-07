# ---------------------------------------------
# Random string generation for ALB naming
# ---------------------------------------------
resource "random_string" "alb" {
  length  = 8
  upper   = false
  special = false
}

# -------------------------------
# Security Group for ALB
# -------------------------------
resource "aws_security_group" "alb_sg" {
  name        = "alb-${random_string.alb.result}-sg"
  description = "Allow traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP from anywhere (IPv4)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description      = "Allow HTTP from anywhere (IPv6)"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description = "Allow HTTPS from anywhere (IPv4)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description      = "Allow HTTPS from anywhere (IPv6)"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description = "Allow all IPv4 outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description      = "Allow all IPv6 outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    ipv6_cidr_blocks = ["::/0"]
  }
}

# -------------------------------
# ALB Instance
# -------------------------------
resource "aws_lb" "alb" {
  name               = "alb-${random_string.alb.result}"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.subnet_id
  ip_address_type    = var.ip_stack

  tags = merge(local.tags_alb,
    {
      Name = "alb-${random_string.alb.result}"
    }
  )

  timeouts {
    create = local.timemout_create
    update = local.timemout_update
    delete = local.timemout_delete
  }

}

# -------------------------------
# Target group
# -------------------------------
resource "aws_lb_target_group" "tg" {
  name        = "tg-http-${random_string.alb.result}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 5
  }
}

# ---------------------------------------
# Instance attachment to the target group
# ---------------------------------------
resource "aws_lb_target_group_attachment" "attachment" {
  #Using a loop to assign multiple instances to a group.
  for_each = toset(var.instance_id)

  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = each.value
  port             = 80
}

# ---------------------------------------
# Import certificate to ACM
# ---------------------------------------
resource "aws_acm_certificate" "certificate" {
  private_key       = file("certs/my-key.pem")
  certificate_body  = file("certs/my-cert.pem")
  certificate_chain = "" # optional; omit or leave blank for self-signed
}


# ---------------------------------------
# Listeners in the ALB
# ---------------------------------------
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  #Redirect all HTTP traffic to HTTPS.
  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.certificate.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

#Path based routing.
resource "aws_lb_listener_rule" "healthz" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 90

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "This is the health check endpoint"
      status_code  = "200"
    }
  }

  condition {
    path_pattern {
      values = ["/healthz"]
    }
  }
}




