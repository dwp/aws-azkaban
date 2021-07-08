check_running_executions() {
  source /assume-role && set +x
  azkaban_host=$(jq -r .azkaban_external.value.fqdn < terraform-output-azkaban/outputs.json)
  azkaban_secret=$(jq -r .azkaban_external.value.secret_name < terraform-output-azkaban/outputs.json)
  azkaban_secret_value=$(aws secretsmanager get-secret-value --secret-id $azkaban_secret | jq -r .SecretBinary | base64 -d)
  azkaban_username=$(echo $azkaban_secret_value | jq -r .azkaban_username)
  azkaban_password=$(echo $azkaban_secret_value | jq -r .azkaban_password)
  azkaban_session_id=$(curl -sS https://$azkaban_host -X POST --data-urlencode "action=login" --data-urlencode "username=$azkaban_username" --data-urlencode password="$azkaban_password" | jq -r .\"session.id\")
  pip -qq install -r ./ci/utility/py/requirements.txt
  running_jobs=$(python ./ci/utility/py/azkaban_jobs.py --session-id $azkaban_session_id https://$azkaban_host)
  count=$(echo $running_jobs | wc -l)
  if [ $count -gt 0 ]; then
    echo $count executions are running: >&2
    echo $running_jobs >&2
    return 1
  else
    echo No executions are running
  fi
}