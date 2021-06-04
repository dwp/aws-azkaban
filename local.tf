locals {
  azkaban_zip_uploader_log_level = {
    development = "DEBUG"
    qa = "INFO"
    integration = "INFO"
    preprod = "INFO"
    production = "INFO"
  }
}
