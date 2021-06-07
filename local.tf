locals {
  azkaban_external_ecs_cluster = data.terraform_remote_state.common.outputs.ecs_cluster_main

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
    preprod     = false
    production  = true
  }

  azkaban_alert_on_running_tasks_less_than_desired = {
    development = true
    qa          = false
    integration = false
    preprod     = false
    production  = true
  }

  azkaban_alert_on_unhealthy_hosts_less_than_running = {
    development = true
    qa          = false
    integration = false
    preprod     = false
    production  = true
  }

  azkaban_external_executor_running_tasks_less_than_desired = "Azkaban External Executor - Running tasks less than desired for more than 5 minutes"
  azkaban_external_web_running_tasks_less_than_desired      = "Azkaban External Web - Running tasks less than desired for more than 5 minutes"

  azkaban_external_web_unhealthy_hosts      = "Azkaban External Web - Number of healthy nodes don't match running tasks for more than 5 minutes"
  azkaban_external_web_zero_unhealthy_hosts = "Azkaban External Web - No healthy hosts but tasks are running"

}
