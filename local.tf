locals {
  azkaban_external_ecs_cluster = data.terraform_remote_state.common.outputs.ecs_cluster_main
  azkaban_user_ecs_cluster     = data.terraform_remote_state.common.outputs.ecs_cluster_main

  azkaban_executor_image  = format("%s:%s", data.terraform_remote_state.management.outputs.ecr_azkaban_executor_url, var.executor_image_version[local.environment])
  azkaban_webserver_image = format("%s:%s", data.terraform_remote_state.management.outputs.ecr_azkaban_webserver_url, var.webserver_image_version[local.environment])

  azkaban_external_executor_image  = format("%s:%s", data.terraform_remote_state.management.outputs.ecr_azkaban_executor_url, var.external_executor_image_version[local.environment])
  azkaban_external_webserver_image = format("%s:%s", data.terraform_remote_state.management.outputs.ecr_azkaban_webserver_url, var.external_webserver_image_version[local.environment])

  azkaban_zip_uploader_log_level = {
    development = "DEBUG"
    qa          = "INFO"
    integration = "INFO"
    preprod     = "INFO"
    production  = "INFO"
  }

  monitoring_topic_arn = data.terraform_remote_state.security-tools.outputs.sns_topic_london_monitoring.arn

  azkaban_external_alert_on_running_tasks_less_than_desired = {
    development = false
    qa          = false
    integration = false
    preprod     = false
    production  = true
  }

  azkaban_external_alert_on_unhealthy_hosts_less_than_running = {
    development = false
    qa          = false
    integration = false
    preprod     = false
    production  = true
  }

  azkaban_external_alert_monitoring_canary = {
    development = true
    qa          = false
    integration = false
    preprod     = false
    production  = true
  }

  azkaban_external_alert_on_500_errors = {
    development = false
    qa          = false
    integration = false
    preprod     = false
    production  = true
  }

  azkaban_external_executor_running_tasks_less_than_desired = "Azkaban External Executor - Running tasks less than desired for more than 5 minutes"
  azkaban_external_web_running_tasks_less_than_desired      = "Azkaban External Web - Running tasks less than desired for more than 5 minutes"
  azkaban_external_web_unhealthy_hosts                      = "Azkaban External Web - Number of healthy nodes don't match running tasks for more than 5 minutes"
  azkaban_external_web_zero_unhealthy_hosts                 = "Azkaban External Web - No healthy hosts but tasks are running"
  azkaban_external_web_5xx_errors                           = "Azkaban External Web - HTTP 500 errors"
  azkaban_external_monitoring_canary_success                = "Azkaban External - Monitoring canary task hasn't ran or failed to succeed in 15 minutes"

  azkaban_user_alert_on_running_tasks_less_than_desired = {
    development = false
    qa          = false
    integration = false
    preprod     = false
    production  = true
  }

  azkaban_user_alert_on_unhealthy_hosts_less_than_running = {
    development = false
    qa          = false
    integration = false
    preprod     = false
    production  = true
  }

  azkaban_user_alert_on_500_errors = {
    development = false
    qa          = false
    integration = false
    preprod     = false
    production  = true
  }


  azkaban_user_executor_running_tasks_less_than_desired = "Azkaban User Executor - Running tasks less than desired for more than 5 minutes"
  azkaban_user_web_running_tasks_less_than_desired      = "Azkaban User Web - Running tasks less than desired for more than 5 minutes"
  azkaban_user_web_unhealthy_hosts                      = "Azkaban User Web - Number of healthy nodes don't match running tasks for more than 5 minutes"
  azkaban_user_web_zero_unhealthy_hosts                 = "Azkaban User Web - No healthy hosts but tasks are running"
  azkaban_user_web_5xx_errors                           = "Azkaban User Web - HTTP 500 errors"

  desired_executor_count = {
    development = 1
    qa          = 1
    integration = 1
    preprod     = 1
    production  = 1
  }

  force_executor_redeploy = {
    development = true
    qa          = false
    integration = false
    preprod     = false
    production  = false
  }

  tanium_service_name = {
    development = jsondecode(data.aws_secretsmanager_secret_version.terraform_secrets.secret_binary).tanium.service_name.non_prod
    qa          = jsondecode(data.aws_secretsmanager_secret_version.terraform_secrets.secret_binary).tanium.service_name.prod
    integration = jsondecode(data.aws_secretsmanager_secret_version.terraform_secrets.secret_binary).tanium.service_name.prod
    preprod     = jsondecode(data.aws_secretsmanager_secret_version.terraform_secrets.secret_binary).tanium.service_name.prod
    production  = jsondecode(data.aws_secretsmanager_secret_version.terraform_secrets.secret_binary).tanium.service_name.prod
  }
}
