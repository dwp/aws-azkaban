locals {
  azkaban_external_cognito_secret = {
    name = data.terraform_remote_state.dataworks_secrets.outputs.azkaban_external_mgmt.name
    arn = data.terraform_remote_state.dataworks_secrets.outputs.azkaban_external_mgmt.arn
  }
}
