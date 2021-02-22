#!/bin/bash

USERNAME=$1
SCRIPT_NAME=$2
SCRIPT_ARGUMENTS=${@:3}

LOG_GROUP_NAME=/aws/emr/azkaban
LOG_DIR=$(ls -td -- /var/log/hadoop/steps/* | head -n 1)
STEP_NAME=$(basename $LOG_DIR)
CONFIG_FILE=/tmp/config_$STEP_NAME.json

cat << EOF > $CONFIG_FILE
{
  "agent": {
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [ { "file_path": "$LOG_DIR/stdout",
                            "log_group_name": "$LOG_GROUP_NAME",
                            "log_stream_name": "$STEP_NAME" },
                          { "file_path": "$LOG_DIR/stderr",
                            "log_group_name": "$LOG_GROUP_NAME",
                            "log_stream_name": "$STEP_NAME" } ]
      }
    }
  }
}
EOF

sudo amazon-cloudwatch-agent-ctl -a append-config -m ec2 -c file:$CONFIG_FILE -s >/dev/null 2>&1

# Synchronize external files on Batch EMR
/home/hadoop/get_scripts.sh component/uc_repos /opt/emr/repos
sudo chmod g+x /opt/emr/repos/chs-uc-lab/build_dataset.sh
sudo chmod g+x /opt/emr/repos/chs-uc-lab/build_views.sh
sudo chmod g+x /opt/emr/repos/chs-payment-timelines/scripts/build_pt.sh

sudo su -c "$SCRIPT_NAME $SCRIPT_ARGUMENTS" - $USERNAME
