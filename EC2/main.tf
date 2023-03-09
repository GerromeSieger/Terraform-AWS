terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_vpc" "default_vpc" {
  default = true
}

data "aws_subnet_ids" "default_subnet" {
  vpc_id = data.aws_vpc.default_vpc.id
}

resource "aws_instance" "prod-server-1" {
  ami             = var.instance_ami
  instance_type   = var.instance_type
  security_groups = [aws_security_group.instances-security-group.name]
}

resource "aws_instance" "prod-server-2" {
  ami             = var.instance_ami
  instance_type   = var.instance_type
  security_groups = [aws_security_group.instances-security-group.name]
}

resource "aws_security_group" "instances-security-group" {
  name = "instances-security-group"
}

resource "aws_security_group_rule" "allow-inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.instances-security-group.id

  from_port   = 8080
  to_port     = 8080
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.load-balancer.arn
  port = 80
  protocol = "HTTP"
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

resource "aws_lb_target_group" "server-instances" {
  name     = "server-instances"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "target-instance-1" {
  target_group_arn = aws_lb_target_group.server-instances.arn
  target_id        = aws_instance.prod-server-1.id
  port             = 8080
}

resource "aws_lb_target_group_attachment" "target-instance-2" {
  target_group_arn = aws_lb_target_group.server-instances.arn
  target_id        = aws_instance.prod-server-2.id
  port             = 8080
}

resource "aws_lb_listener_rule" "listener-rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.server-instances.arn
  }
}


resource "aws_security_group" "alb-security-group" {
  name = "alb-security-group"
}

resource "aws_security_group_rule" "allow-http-inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.alb-security-group.id

  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

}

resource "aws_security_group_rule" "allow-all-outbound" {
  type              = "egress"
  security_group_id = aws_security_group.alb-security-group.id

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

}

resource "aws_lb" "load-balancer" {
  name               = "load-balancer"
  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.default_subnet.ids
  security_groups    = [aws_security_group.alb-security-group.id]
}

resource "aws_route53_zone" "gerromeapp" {
  name = "gerromeapp.com"
}

resource "aws_route53_record" "root" {
  zone_id = aws_route53_zone.gerromeapp.zone_id
  name    = "gerromeapp.com"
  type    = "A"

  alias {
    name                   = aws_lb.load_balancer.dns_name
    zone_id                = aws_lb.load_balancer.zone_id
    evaluate_target_health = true
  }
}
