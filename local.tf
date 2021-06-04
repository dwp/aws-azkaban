locals {
  azkaban_zip_uploader_log_level = {
    development = "DEBUG"
    qa          = "INFO"
    integration = "INFO"
    preprod     = "INFO"
    production  = "INFO"
  }

  monitoring_topic_arn = data.terraform_remote_state.security-tools.outputs.sns_topic_london_monitoring.arn

  external_alert_on_running_tasks_less_than_desired = {
    development = true
    qa          = false
    integration = false
    preprod     = false
    production  = true
  }

  external_running_tasks_less_than_desired = "Azkaban External - Running tasks less than desired for more than 5 minutes"

}
