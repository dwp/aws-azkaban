#!/bin/bash

aws s3 cp s3://${config_bucket}/workflow-manager/azkaban/impact-measures.zip /tmp/impact-measures.zip
unzip /tmp/impact-measures.zip -d /tmp
