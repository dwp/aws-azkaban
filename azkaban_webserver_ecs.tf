resource "aws_ecs_task_definition" "azkaban_webserver" {
  family                   = "azkaban-webserver"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "4096"
  task_role_arn            = aws_iam_role.azkaban_webserver.arn
  execution_role_arn       = data.terraform_remote_state.common.outputs.ecs_task_execution_role.arn
  container_definitions    = "[${data.template_file.azkaban_webserver_definition.rendered}, ${data.template_file.azkaban_webserver_jmx_exporter_definition.rendered}]"
}

data "template_file" "azkaban_webserver_definition" {
  template = file("${path.module}/container_definition.tpl")
  vars = {
    name          = "azkaban-webserver"
    group_name    = "azkaban"
    cpu           = var.fargate_cpu
    image_url     = data.terraform_remote_state.management.outputs.ecr_azkaban_webserver_url
    memory        = var.fargate_memory
    user          = "root"
    ports         = jsonencode([jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_webserver_port])
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

data "template_file" "azkaban_webserver_jmx_exporter_definition" {
  template = file("${path.module}/container_definition.tpl")
  vars = {
    name          = "azkaban-webserver-jmx-exporter"
    group_name    = "jmx_exporter"
    cpu           = var.fargate_cpu
    image_url     = format("%s:%s", data.terraform_remote_state.management.outputs.ecr_jmx_exporter_url, var.image_versions.jmx-exporter)
    memory        = var.fargate_memory
    user          = "root"
    ports         = jsonencode([5556])
    log_group     = aws_cloudwatch_log_group.workflow_manager.name
    region        = var.region
    config_bucket = data.terraform_remote_state.common.outputs.config_bucket.id

    mount_points = jsonencode([])
    environment_variables = jsonencode([
      {
        "name" : "JMX_EXPORTER_ROLE",
        "value" : "web-server"
      },
      {
        name  = "PROMETHEUS",
        value = "true"
      }
    ])

  }
}

resource "aws_ecs_service" "azkaban_webserver" {
  name             = "azkaban-webserver"
  cluster          = data.terraform_remote_state.common.outputs.ecs_cluster_main.id
  task_definition  = aws_ecs_task_definition.azkaban_webserver.arn
  platform_version = var.platform_version
  desired_count    = 1
  launch_type      = "FARGATE"
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  network_configuration {
    security_groups = [aws_security_group.azkaban_webserver.id, aws_security_group.workflow_manager_common.id]
    subnets         = aws_subnet.workflow_manager_private.*.id
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.azkaban_webserver.arn
    container_name   = "azkaban-webserver"
    container_port   = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_webserver_port
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.azkaban_webserver.arn
    container_name = "azkaban-webserver"
  }
}

resource "aws_service_discovery_service" "azkaban_webserver" {
  name = "azkaban-webserver"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.workflow_manager.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }
}
