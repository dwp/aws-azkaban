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
  port              = var.http_port
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "FORBIDDEN"
      status_code  = "403"
    }
  }
}

resource "aws_lb_target_group" "azkaban_webserver" {
  name        = "azkaban-webserver-http"
  port        = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_webserver_port
  protocol    = "HTTP"
  vpc_id      = module.workflow_manager_vpc.vpc.id
  target_type = "ip"

  health_check {
    port    = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_webserver_port
    path    = "/"
    matcher = "200"
  }

  stickiness {
    enabled = true
    type    = "lb_cookie"
  }
  tags = merge(local.common_tags, { Name = "azkaban-webserver" })
}

resource "aws_lb_listener_rule" "azkaban_webserver" {
  listener_arn = aws_lb_listener.workflow_manager.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.azkaban_webserver.arn
  }

  condition {
    field  = "host-header"
    values = [aws_route53_record.azkaban_loadbalancer.fqdn]
  }
}

resource "aws_security_group" "workflow_manager_loadbalancer" {
  vpc_id = module.workflow_manager_vpc.vpc.id
  tags   = merge(local.common_tags, { Name = "${local.name}-loadbalancer" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_ingress_https" {
  description       = "Enable inbound connectivity from whitelisted endpoints"
  from_port         = var.https_port
  protocol          = "tcp"
  security_group_id = aws_security_group.workflow_manager_loadbalancer.id
  to_port           = var.https_port
  type              = "ingress"
  cidr_blocks       = var.whitelist_cidr_blocks
}

resource "aws_security_group_rule" "allow_loadbalancer_egress_azkaban_webserver" {
  description              = "Allow loadbalancer to access azkaban webserver user interface"
  type                     = "egress"
  to_port                  = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_webserver_port
  protocol                 = "tcp"
  from_port                = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_webserver_port
  security_group_id        = aws_security_group.workflow_manager_loadbalancer.id
  source_security_group_id = aws_security_group.azkaban_webserver.id
}
