output "secrets" {
  value = {
    executor  = aws_secretsmanager_secret.azkaban_executor_password
    webserver = aws_secretsmanager_secret.azkaban_webserver_password
  }
}

output "ecs_services" {
  value = {
    executor  = aws_ecs_service.azkaban_executor
    webserver = aws_ecs_service.azkaban_executor
  }
}

output "truncate_table_lambda" {
  value = aws_lambda_function.truncate_table
  sensitive = true
}

output "truncate_external_table_lambda" {
  value = aws_lambda_function.truncate_external_table
  sensitive = true
}

output "aws_route_table" {
  value = {
    workflow_manager_private = aws_route_table.workflow_manager_private
  }
}

output "workflow_manager_vpc" {
  value = module.workflow_manager_vpc
}

output "azkaban_webserver_sg" {
  value = {
    id = aws_security_group.azkaban_webserver.id
  }
}

output "azkaban_external" {
  value = {
    fqdn        = aws_route53_record.azkaban_external.fqdn
    secret_name = data.aws_secretsmanager_secret.azkaban_external_cognito.name
  }
}
