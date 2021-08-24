locals {
  azkaban_external_ecs_cluster = data.terraform_remote_state.common.outputs.ecs_cluster_main
  azkaban_user_ecs_cluster = data.terraform_remote_state.common.outputs.ecs_cluster_main

  azkaban_zip_uploader_log_level = {
    development = "DEBUG"
    qa          = "INFO"
    integration = "INFO"
    preprod     = "INFO"
    production  = "INFO"
  }

  monitoring_topic_arn = data.terraform_remote_state.security-tools.outputs.sns_topic_london_monitoring.arn

  azkaban_external_alert_on_running_tasks_less_than_desired = {
    development = true
    qa          = false
    integration = false
    preprod     = true
    production  = true
  }

  azkaban_alert_on_running_tasks_less_than_desired = {
    development = true
    qa          = false
    integration = false
    preprod     = true
    production  = true
  }

  azkaban_alert_on_unhealthy_hosts_less_than_running = {
    development = true
    qa          = false
    integration = false
    preprod     = true
    production  = true
  }

  azkaban_external_executor_running_tasks_less_than_desired = "Azkaban External Executor - Running tasks less than desired for more than 5 minutes"
  azkaban_external_web_running_tasks_less_than_desired      = "Azkaban External Web - Running tasks less than desired for more than 5 minutes"
  azkaban_external_web_unhealthy_hosts      = "Azkaban External Web - Number of healthy nodes don't match running tasks for more than 5 minutes"
  azkaban_external_web_zero_unhealthy_hosts = "Azkaban External Web - No healthy hosts but tasks are running"
  azkaban_external_web_5xx_errors = "Azkaban External Web - External Web HTTP 500 errors"

  azkaban_user_alert_on_running_tasks_less_than_desired = {
    development = true
    qa          = false
    integration = false
    preprod     = true
    production  = true
  }

  azkaban_user_alert_on_running_tasks_less_than_desired = {
    development = true
    qa          = false
    integration = false
    preprod     = true
    production  = true
  }

  azkaban_alert_on_unhealthy_hosts_less_than_running = {
    development = true
    qa          = false
    integration = false
    preprod     = true
    production  = true
  }

  azkaban_user_executor_running_tasks_less_than_desired = "Azkaban User Executor - Running tasks less than desired for more than 5 minutes"
  azkaban_user_web_running_tasks_less_than_desired      = "Azkaban User Web - Running tasks less than desired for more than 5 minutes"
  azkaban_user_web_unhealthy_hosts      = "Azkaban User Web - Number of healthy nodes don't match running tasks for more than 5 minutes"
  azkaban_user_web_zero_unhealthy_hosts = "Azkaban User Web - No healthy hosts but tasks are running"
  azkaban_user_web_5xx_errors = "Azkaban User Web - External Web HTTP 500 errors"

  desired_executor_count = {
    development = 3
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

}
