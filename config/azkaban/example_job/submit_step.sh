#!/bin/bash
CLUSTER_ID=`aws emr list-clusters --cluster-states WAITING | jq '.Clusters[] | select(.Name == "aws-analytical-env") | .Id' | tr -d '\"'`
STEP_ID=`aws emr add-steps --cluster-id $CLUSTER_ID --steps Type=CUSTOM_JAR,Name=$1,ActionOnFailure=CONTINUE,Jar=command-runner.jar,Args=s3://${config_bucket}/$2 | jq .StepIds[] | tr -d "\""`
STEP_STATE="PENDING"

while [ "$STEP_STATE" = "PENDING" ]
do
    sleep 5
    STEP_STATE=`aws emr list-steps --cluster-id $CLUSTER_ID --step-id $STEP_ID | jq .Steps[].Status.State | tr -d "\""`
    echo "{\"step_state\": \"$STEP_STATE\"}"
done

echo "{\"step_state\": \"$STEP_STATE\"}" > $JOB_OUTPUT_PROP_FILE
