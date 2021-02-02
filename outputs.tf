output "rds_db" {
  value = aws_rds_cluster.azkaban_database
}

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
}

output "workflow_manager_vpc" {
  value = module.workflow_manager_vpc
}
