#!/bin/bash 
 
script_dir=$(dirname $0)
 
echo "Dropping all other expired executors from table"
mysql -h $DB_HOST -u$DB_USERNAME -p$DB_PASSWORD $DB_NAME -e \
    "DELETE FROM executors;"
 
echo "Creating tables in database if they do not exist using create-all-sql.sql"
mysql -h $DB_HOST -u$DB_USERNAME -p$DB_PASSWORD $DB_NAME < /azkaban-db/create-all-sql-0.1.0-SNAPSHOT.sql
 
$${script_dir}/internal/internal-start-executor.sh "$@"
