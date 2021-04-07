resource "aws_ecs_task_definition" "azkaban_external_webserver" {
  family                   = "azkaban-external-webserver"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "4096"
  task_role_arn            = aws_iam_role.azkaban_webserver.arn
  execution_role_arn       = data.terraform_remote_state.common.outputs.ecs_task_execution_role.arn
  container_definitions    = "[${data.template_file.azkaban_external_webserver_definition.rendered}, ${data.template_file.azkaban_webserver_jmx_exporter_definition.rendered}]"
}

data "template_file" "azkaban_external_webserver_definition" {
  template = file("${path.module}/container_definition.tpl")
  vars = {
    name          = "azkaban-external-webserver"
    group_name    = "azkaban_external"
    cpu           = var.fargate_cpu
    image_url     = data.terraform_remote_state.management.outputs.ecr_azkaban_webserver_url
    memory        = var.fargate_memory
    user          = "root"
    ports         = jsonencode([jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_external_webserver_port])
    log_group     = aws_cloudwatch_log_group.workflow_manager.name
    region        = var.region
    config_bucket = data.terraform_remote_state.common.outputs.config_bucket.id

    mount_points = jsonencode([])

    environment_variables = jsonencode([
      {
        "name" : "AZKABAN_ROLE",
        "value" : "web-server"
      },
      {
        "name" : "KEYSTORE_DATA",
        "value" : jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).keystore_data
      }
    ])
  }
}

resource "aws_ecs_service" "azkaban_external_webserver" {
  name                               = "azkaban-external-webserver"
  cluster                            = data.terraform_remote_state.common.outputs.ecs_cluster_main.id
  task_definition                    = aws_ecs_task_definition.azkaban_external_webserver.arn
  platform_version                   = var.platform_version
  desired_count                      = 1
  launch_type                        = "FARGATE"
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  network_configuration {
    security_groups = [aws_security_group.azkaban_external_webserver.id, aws_security_group.workflow_manager_common.id]
    subnets         = aws_subnet.workflow_manager_private.*.id
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.azkaban_external_webserver.arn
    container_name   = "azkaban-external-webserver"
    container_port   = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_external_webserver_port
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.azkaban_external_webserver.arn
    container_name = "azkaban-external-webserver"
  }
}

resource "aws_service_discovery_service" "azkaban_external_webserver" {
  name = "azkaban-external-webserver"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.workflow_manager.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }
}
