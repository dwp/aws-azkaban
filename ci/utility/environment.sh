init() {
  source /assume-role
  pip -qq install -r $(source_directory)/requirements.txt
}

check_running_executions() {
  init
  azkaban_host=$(azkaban_host)
  echo azkaban_host: \'$azkaban_host\'
  azkaban_secret=$(azkaban_secret)
  echo azkaban_secret: \`$azkaban_secret\`
  azkaban_secret_value=$(azkaban_secret_value $azkaban_secret)
  echo azkaban_secret_value: \`$azkaban_secret_value\`
  azkaban_username=$(azkaban_username $azkaban_secret_value)
  azkaban_password=$(azkaban_password $azkaban_secret_value)
  azkaban_session_id=$(azkaban_session_id $azkaban_host $azkaban_username $azkaban_password)
  running_jobs=$(azkaban_running_jobs $azkaban_host $azkaban_session_id)
  count=$(echo $running_jobs | wc -l)
  if [ $count -gt 0 ]; then
    echo $count executions are running: >&2
    echo $running_jobs >&2
    return 1
  else
    echo No executions are running
  fi
}

azkaban_running_jobs() {
  local -r azkaban_host=${1:?Usage: ${FUNCNAME[0]} azkaban_host azkaban_session_id}
  local -r azkaban_session_id=${2:?Usage: ${FUNCNAME[0]} azkaban_host azkaban_session_id}
  python $(source_directory)/azkaban_jobs.py --session-id $azkaban_session_id https://$azkaban_host
}

azkaban_host() {
  jq -r .azkaban_external.value.fqdn < terraform-output-azkaban/outputs.json
}

azkaban_secret() {
  jq -r .azkaban_external.value.secret_name < terraform-output-azkaban/outputs.json
}

azkaban_secret_value() {
  local -r azkaban_secret=${1:?Usage: ${FUNCNAME[0]} azkaban_secret}
  aws secretsmanager get-secret-value --secret-id $azkaban_secret | jq -r .SecretBinary | base64 -d
}

azkaban_username() {
  local -r azkaban_secret_value=${1:?Usage: ${FUNCNAME[0]} azkaban_secret_value}
  echo $azkaban_secret_value | jq -r .azkaban_username
}

azkaban_password() {
  local -r azkaban_secret_value=${1:?Usage: ${FUNCNAME[0]} azkaban_secret_value}
  echo $azkaban_secret_value | jq -r .azkaban_password
}

azkaban_session_id() {
  local -r azkaban_host=${1:?Usage: ${FUNCNAME[0]} azkaban_host azkaban_username azkaban_password}
  local -r azkaban_username=${2:?Usage: ${FUNCNAME[0]} azkaban_host azkaban_username azkaban_password}
  local -r azkaban_password=${3:?Usage: ${FUNCNAME[0]} azkaban_host azkaban_username azkaban_password}
  curl -sS https://$azkaban_host -X POST \
    --data-urlencode "action=login" \
    --data-urlencode "username=$azkaban_username" \
    --data-urlencode "password=$azkaban_password" | jq -r .\"session.id\"
}
source_directory() {
  echo ./aws-azkaban/ci/utility/py
}