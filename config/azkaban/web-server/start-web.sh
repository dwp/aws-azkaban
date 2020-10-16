#!/bin/bash

script_dir=$(dirname $0)

echo "Creating tables in database if they do not exist using create-all-sql.sql"
mysql -h ${db_host} -u${db_username} -p${db_password} ${db_name} < /azkaban-db/create-all-sql-0.1.0-SNAPSHOT.sql

$${script_dir}/internal/internal-start-web.sh "$@"
