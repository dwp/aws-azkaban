init() {
  source /assume-role && set +x
  pip -qq install -r $(source_directory)/requirements.txt
}

azkaban_authenticate() {
  azkaban_host=$(azkaban_host)
  azkaban_secret=$(azkaban_secret)
  azkaban_secret_value=$(azkaban_secret_value "$azkaban_secret")
  azkaban_username=$(azkaban_username "$azkaban_secret_value")
  azkaban_password=$(azkaban_password "$azkaban_secret_value")
  azkaban_session_id "$azkaban_host" "$azkaban_username" "$azkaban_password"
}

azkaban_running_jobs() {
  local azkaban_host=${1:?}
  local azkaban_session_id=${2:?}
  python $(source_directory)/azkaban_jobs.py --session-id $azkaban_session_id https://$azkaban_host
}

azkaban_host() {
  jq -r .azkaban_external.value.fqdn < terraform-output-azkaban/outputs.json
}

azkaban_secret() {
  jq -r .azkaban_external.value.secret_name < terraform-output-azkaban/outputs.json
}

azkaban_secret_value() {
  local azkaban_secret=${1:?}
  aws secretsmanager get-secret-value --secret-id $azkaban_secret | jq -r .SecretBinary | base64 -d
}

azkaban_username() {
  local azkaban_secret_value=${1:?}
  echo $azkaban_secret_value | jq -r .azkaban_username
}

azkaban_password() {
  local azkaban_secret_value=${1:?}
  echo $azkaban_secret_value | jq -r .azkaban_password
}

azkaban_session_id() {
  local azkaban_host=${1:?}
  local azkaban_username=${2:?}
  local azkaban_password=${3:?}
  curl -sS https://$azkaban_host -X POST \
    --data-urlencode "action=login" \
    --data-urlencode "username=$azkaban_username" \
    --data-urlencode "password=$azkaban_password" | jq -r .\"session.id\"
}

source_directory() {
  echo ./aws-azkaban/ci/utility/py
}
