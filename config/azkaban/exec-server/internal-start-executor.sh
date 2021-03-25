#!/bin/bash

azkaban_dir=/azkaban-exec-server

# Specifies location of azkaban.properties, log4j.properties files
# Change if necessary
conf=$azkaban_dir/conf

if [[ -z "$tmpdir" ]]; then
    tmpdir=/tmp
fi

for file in $azkaban_dir/lib/*.jar;
do
    CLASSPATH=$CLASSPATH:$file
done

for file in $azkaban_dir/extlib/*.jar;
do
    CLASSPATH=$CLASSPATH:$file
done

for file in $azkaban_dir/plugins/*/*.jar;
do
    CLASSPATH=$CLASSPATH:$file
done

if [ "$HADOOP_HOME" != "" ]; then
    echo "Using Hadoop from $HADOOP_HOME"
    CLASSPATH=$CLASSPATH:$HADOOP_HOME/conf:$HADOOP_HOME/*
    JAVA_LIB_PATH="-Djava.library.path=$HADOOP_HOME/lib/native/Linux-amd64-64"
else
    echo "Error: HADOOP_HOME is not set. Hadoop job types will not run properly."
fi

if [ "$HIVE_HOME" != "" ]; then
    echo "Using Hive from $HIVE_HOME"
    CLASSPATH=$CLASSPATH:$HIVE_HOME/conf:$HIVE_HOME/lib/*
fi

echo $azkaban_dir;
echo $CLASSPATH;

executorport=`cat $conf/azkaban.properties | grep executor.port | cut -d = -f 2`
echo "Starting AzkabanExecutorServer on port $executorport ..."
serverpath=`pwd`

if [[ -z "$AZKABAN_OPTS" ]]; then
    AZKABAN_OPTS="-Xmx3G"
fi
# Set the log4j configuration file
if [ -f $conf/log4j.properties ]; then
    AZKABAN_OPTS="$AZKABAN_OPTS -Dlog4j.configuration=file:$conf/log4j.properties -Dlog4j.log.dir=$azkaban_dir/logs"
else
    echo "Exit with error: $conf/log4j.properties file doesn't exist."
    exit 1;
fi
AZKABAN_OPTS="$AZKABAN_OPTS -server -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.local.only=false -Dcom.sun.management.jmxremote.port=9998 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Djava.io.tmpdir=$tmpdir -Dexecutorport=$executorport -Dserverpath=$serverpath"

bash -c 'while true; do curl_response=`curl -k -w "%%{http_code}\\n" http://localhost:${azkaban_executor_port}/executor?action=activate -o /dev/null --connect-timeout 3 --max-time 5`; if [ $curl_response -ne "200" ]; then sleep 5; else break; fi done' &

export SID=$(curl -k -X POST --data "action=login&username=${admin_username}&password=${admin_password}" https://${azkaban_webserver_hostname}:${azkaban_webserver_port}  | jq -r '."session.id"')
bash -c 'sleep 20s; curl -k --data "session.id=$SID" https://${azkaban_webserver_hostname}:${azkaban_webserver_port}/executor?ajax=reloadExecutors' &

java $AZKABAN_OPTS $JAVA_LIB_PATH -cp $CLASSPATH azkaban.execapp.AzkabanExecutorServer -conf $conf $@
