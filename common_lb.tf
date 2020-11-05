resource "aws_lb" "workflow_manager" {
  name               = local.name
  internal           = true
  load_balancer_type = "application"
  subnets            = aws_subnet.workflow_manager_private.*.id
  security_groups    = [aws_security_group.workflow_manager_loadbalancer.id]
  tags               = merge(local.common_tags, { Name = "${local.name}-loadbalancer" })
}

resource "aws_lb_listener" "workflow_manager" {
  load_balancer_arn = aws_lb.workflow_manager.arn
  port              = var.https_port
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.azkaban_loadbalancer.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.azkaban_webserver.arn
  }
}

resource "aws_lb_target_group" "azkaban_webserver" {
  name        = "azkaban-webserver-http"
  port        = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_webserver_port
  protocol    = "HTTPS"
  vpc_id      = module.workflow_manager_vpc.vpc.id
  target_type = "ip"

  health_check {
    protocol = "HTTPS"
    port     = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_webserver_port
    path     = "/"
    matcher  = "200"
  }

  stickiness {
    enabled = true
    type    = "lb_cookie"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, { Name = "azkaban-webserver" })
}

resource "aws_security_group" "workflow_manager_loadbalancer" {
  vpc_id = module.workflow_manager_vpc.vpc.id
  tags   = merge(local.common_tags, { Name = "${local.name}-loadbalancer" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_loadbalancer_egress_azkaban_webserver" {
  description              = "Allow loadbalancer to access azkaban webserver user interface"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_webserver_port
  to_port                  = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_webserver_port
  security_group_id        = aws_security_group.workflow_manager_loadbalancer.id
  source_security_group_id = aws_security_group.azkaban_webserver.id
}
