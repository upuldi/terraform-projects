resource "aws_lb" "public" {
  name               = var.name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids
  tags = {
    Name = var.name
    App  = var.app
  }
}

resource "aws_lb_target_group" "public" {
  name        = "${var.name}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  tags = {
    Name = var.name
    App  = var.app
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.public.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public.arn
  }
}

output "alb_dns_name" {
  value = aws_lb.public.dns_name
}
output "target_group_arn" {
  value = aws_lb_target_group.public.arn
}

# output "alb_security_group_id" {
#   description = "security group id of ALB"
#   value = aws_security_group.public_sg.id
# }
