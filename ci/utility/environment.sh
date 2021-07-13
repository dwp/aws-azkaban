init() {
  set +x
  source /assume-role && set +x
  pip -qq install -r $(source_directory)/requirements.txt
}

azkaban_shared_session_id() {
  cat azkaban-session-id/azkaban-session-id.txt
}

azkaban_session_id() {
  azkaban_host=$(azkaban_host)
  azkaban_secret=$(azkaban_secret)
  azkaban_secret_value=$(azkaban_secret_value "$azkaban_secret")
  azkaban_username=$(azkaban_username "$azkaban_secret_value")
  azkaban_password=$(azkaban_password "$azkaban_secret_value")
  azkaban_authenticate "$azkaban_host" "$azkaban_username" "$azkaban_password"
}

azkaban_running_jobs() {
  local azkaban_host=${1:?}
  local azkaban_session_id=${2:?}
  python $(source_directory)/azkaban_jobs.py --session-id $azkaban_session_id https://$azkaban_host
}

azkaban_authenticate() {
  local azkaban_host=${1:?}
  local azkaban_username=${2:?}
  local azkaban_password=${3:?}
  curl -sS https://$azkaban_host -X POST \
    --data-urlencode "action=login" \
    --data-urlencode "username=$azkaban_username" \
    --data-urlencode "password=$azkaban_password" | jq -r .\"session.id\"
}

azkaban_delete_project() {
  local azkaban_host=${1:?}
  local azkaban_session_id=${2:?}
  local azkaban_project_name=${3:?}
  curl --get https://$azkaban_host/manager \
    --data-urlencode "delete=true" \
    --data-urlencode "session.id=$azkaban_session_id" \
    --data-urlencode "project=$azkaban_project_name"
}

azkaban_create_project() {
  local azkaban_host=${1:?}
  local azkaban_session_id=${2:?}
  local azkaban_project_name=${3:?}
  curl https://$azkaban_host/manager -X POST \
    --data-urlencode "action=create" \
    --data-urlencode "session.id=$azkaban_session_id" \
    --data-urlencode "name=$azkaban_project_name" \
    --data-urlencode "description=Project run by the end to end tests"
}

azkaban_upload_project() {
  local azkaban_host=${1:?}
  local azkaban_session_id=${2:?}
  local azkaban_project_name=${3:?}
  local azkaban_zip_file=${4:?}

  curl -X POST \
    -H "X-Requested-With: XMLHttpRequest" \
    --form "ajax=upload" \
    --form "session.id=$azkaban_session_id" \
    --form "project=$azkaban_project_name" \
    --form "file=@$azkaban_zip_file;type=application/zip" \
    https://$azkaban_host/manager
}

# shellcheck disable=SC2155
azkaban_execute_flow() {
  local azkaban_host=${1:?}
  local azkaban_session_id=${2:?}
  local azkaban_project=${3:?}
  local azkaban_flow=${4:?}

  local response=$(curl -sS -X POST \
      -H "X-Requested-With: XMLHttpRequest" \
      --data-urlencode "session.id=$azkaban_session_id" \
      --data-urlencode "ajax=executeFlow" \
      --data-urlencode "project=$azkaban_project" \
      --data-urlencode "flow=$azkaban_flow" \
      "https://$azkaban_host/executor")

    local error=$(echo "$response" | jq -r .error)

    if [ -n "$error" ] && [ "$error" != "null" ]; then
      echo Failed to execute "$azkaban_project"/"$azkaban_flow": "$error" >&2
      return 1
    fi

    echo "$response" | jq -r .execid
}

azkaban_flow_status() {
  local azkaban_host=${1:?}
  local azkaban_session_id=${2:?}
  local azkaban_execution_id=${3:?}

  local response=$(curl -sS --get \
    -H "X-Requested-With: XMLHttpRequest" \
    --data-urlencode "session.id=$azkaban_session_id" \
    --data-urlencode "ajax=fetchexecflow" \
    --data-urlencode "execid=$azkaban_execution_id" \
    "https://$azkaban_host/executor")

  echo $response | jq -r .status
}

azkaban_start_webserver() {
  local webserver_service=${1:?}
  aws ecs update-service \
    --cluster main \
    --service "$webserver_service" \
    --desired-count 1 > /dev/null
}

azkaban_webserver_instance_count() {
  local webserver_service=${1:?}
  aws ecs describe-services \
    --cluster main \
    --services "$webserver_service" | jq -r '.services[0].runningCount'
}

azkaban_secret_value() {
  local azkaban_secret=${1:?}
  aws secretsmanager get-secret-value --secret-id $azkaban_secret | jq -r .SecretBinary | base64 -d
}

azkaban_secret() {
  jq -r .azkaban_external.value.secret_name < terraform-output-azkaban/outputs.json
}

azkaban_host() {
  jq -r .azkaban_external.value.fqdn < terraform-output-azkaban/outputs.json
}

azkaban_username() {
  local azkaban_secret_value=${1:?}
  echo $azkaban_secret_value | jq -r .azkaban_username
}

azkaban_password() {
  local azkaban_secret_value=${1:?}
  echo $azkaban_secret_value | jq -r .azkaban_password
}

source_directory() {
  echo ./aws-azkaban/ci/utility/py
}
