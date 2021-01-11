#!/bin/bash

LOG_GROUP_NAME=/aws/emr/azkaban
CONFIG_FILE=/opt/aws/amazon-cloudwatch-agent/bin/config.json
LOG_DIR=$(ls -td -- /var/log/hadoop/steps/* | head -n 1)
STEP_NAME=$(basename $LOG_DIR)

if [ ! -f "$CONFIG_FILE" ]; then
  cat << EOF > $CONFIG_FILE
{
  "agent": {
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": []
      }
    }
  }
}
EOF
fi

sudo cat $CONFIG_FILE | jq ".logs.logs_collected.files.collect_list += [{\"file_path\": \"$LOG_DIR/stdout\", \"log_group_name\": \"$LOG_GROUP_NAME\", \"log_stream_name\": \"$STEP_NAME\"}, {\"file_path\": \"$LOG_DIR/stderr\", \"log_group_name\": \"$LOG_GROUP_NAME\", \"log_stream_name\": \"$STEP_NAME\"}]" > /tmp/config.json
sudo mv -f /tmp/config.json $CONFIG_FILE
sudo amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:$CONFIG_FILE -s >/dev/null 2>&1

# Synchronize external files on Batch EMR
/home/hadoop/get_scripts.sh component/uc_repos /opt/emr/repos

sudo su -c "$1 $3" - $2
