resource "aws_ecs_task_definition" "azkaban_external_executor" {
  family                   = "azkaban-external-executor"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "4096"
  task_role_arn            = aws_iam_role.azkaban_executor.arn
  execution_role_arn       = data.terraform_remote_state.common.outputs.ecs_task_execution_role.arn
  container_definitions    = "[${data.template_file.azkaban_external_executor_definition.rendered}]"
}

data "template_file" "azkaban_external_executor_definition" {
  template = file("${path.module}/container_definition.tpl")
  vars = {
    name          = "azkaban-external-executor"
    group_name    = "azkaban"
    group_value   = "azkaban_external"
    cpu           = var.fargate_cpu
    image_url     = local.azkaban_external_executor_image
    memory        = var.fargate_memory
    user          = "root"
    ports         = jsonencode([jsondecode(data.aws_secretsmanager_secret_version.azkaban_external.secret_binary).ports.azkaban_executor_port])
    log_group     = aws_cloudwatch_log_group.workflow_manager.name
    region        = var.region
    config_bucket = data.terraform_remote_state.common.outputs.config_bucket.id

    mount_points = jsonencode([])

    environment_variables = jsonencode([
      {
        "name" : "AZKABAN_ROLE",
        "value" : "exec-server"
      },
      {
        "name" : "USER_POOL_ID",
        "value" : data.terraform_remote_state.aws_analytical_environment_cognito.outputs.cognito.user_pool_id
      },
      {
        "name" : "COGNITO_ROLE_ARN",
        "value" : aws_iam_role.aws_analytical_env_cognito_read_only_role.arn
      },
      {
        "name" : "HTTP_PROXY",
        "value" : "http://${aws_vpc_endpoint.internet_proxy.dns_entry[0].dns_name}:${var.internet_proxy_port}"
      },
      {
        "name" : "HTTPS_PROXY",
        "value" : "http://${aws_vpc_endpoint.internet_proxy.dns_entry[0].dns_name}:${var.internet_proxy_port}"
      },
      {
        "name" : "NO_PROXY",
        "value" : "127.0.0.1,azkaban-external-webserver.${local.service_discovery_fqdn},${aws_rds_cluster.azkaban_external_database.endpoint},${local.vpce_no_proxy}"
      }
    ])
  }
}

resource "aws_ecs_service" "azkaban_external_executor" {
  name                               = "azkaban-external-executor"
  cluster                            = data.terraform_remote_state.common.outputs.ecs_cluster_main.id
  task_definition                    = aws_ecs_task_definition.azkaban_external_executor.arn
  platform_version                   = var.platform_version
  desired_count                      = local.desired_executor_count[local.environment]
  force_new_deployment               = local.force_executor_redeploy[local.environment]
  launch_type                        = "FARGATE"
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  network_configuration {
    security_groups = [aws_security_group.azkaban_external_executor.id, aws_security_group.workflow_manager_common.id]
    subnets         = aws_subnet.workflow_manager_private.*.id
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.azkaban_external_executor.arn
    container_name = "azkaban-external-executor"
  }
}

resource "aws_service_discovery_service" "azkaban_external_executor" {
  name = "azkaban-external-executor"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.workflow_manager.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }
}
