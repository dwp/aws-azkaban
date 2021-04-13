resource "aws_lb" "azkaban_external" {
  name               = "azkaban-external"
  internal           = false
  load_balancer_type = "application"
  subnets            = aws_subnet.azkaban_public.*.id
  security_groups    = [aws_security_group.azkaban_external_loadbalancer.id]
  tags               = merge(local.common_tags, { Name = "${local.name}-azkaban-external-loadbalancer" })
}

resource "aws_lb_listener" "azkaban_external" {
  load_balancer_arn = aws_lb.azkaban_external.arn
  port              = var.https_port
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.azkaban_external_loadbalancer.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.azkaban_external_webserver.arn
  }
}

resource "aws_lb_target_group" "azkaban_external_webserver" {
  name        = "azkaban-external-webserver-http"
  port        = jsondecode(data.aws_secretsmanager_secret_version.azkaban_external.secret_binary).ports.azkaban_webserver_port
  protocol    = "HTTPS"
  vpc_id      = module.workflow_manager_vpc.vpc.id
  target_type = "ip"

  health_check {
    protocol = "HTTPS"
    port     = jsondecode(data.aws_secretsmanager_secret_version.azkaban_external.secret_binary).ports.azkaban_webserver_port
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

  tags = merge(local.common_tags, { Name = "azkaban-external-webserver" })
}

resource "aws_security_group" "azkaban_external_loadbalancer" {
  name   = "azkaban-external-lb-sg"
  vpc_id = module.workflow_manager_vpc.vpc.id
  tags   = merge(local.common_tags, { Name = "${local.name}-azkaban-external-loadbalancer" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_external_loadbalancer_egress_azkaban_external_webserver" {
  description              = "Allow external loadbalancer to access azkaban external webserver user interface"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = jsondecode(data.aws_secretsmanager_secret_version.azkaban_external.secret_binary).ports.azkaban_webserver_port
  to_port                  = jsondecode(data.aws_secretsmanager_secret_version.azkaban_external.secret_binary).ports.azkaban_webserver_port
  security_group_id        = aws_security_group.azkaban_external_loadbalancer.id
  source_security_group_id = aws_security_group.azkaban_external_webserver.id
}

resource "aws_security_group_rule" "allow_external_loadbalancer_ingress_azkaban_external_webserver" {
  description       = "Allow external loadbalancer to access azkaban external webserver user interface"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  security_group_id = aws_security_group.azkaban_external_loadbalancer.id
  cidr_blocks       = var.whitelist_cidr_blocks
}
