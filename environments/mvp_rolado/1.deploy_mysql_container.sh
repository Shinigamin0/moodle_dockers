#!/bin/bash
source ./conf
echo "Desplegando MySql"
docker pull $mysql_image_name
docker run \
    --network=moodle \
    -p 3306:3306 \
    --name $moodle_db_container_name \
    -v $(pwd)/db:/var/lib/mysql \
    -e MYSQL_ROOT_PASSWORD=$mysql_root_password \
    -e MYSQL_DATABASE=$moodle_db_name \
    -e MYSQL_USER=$moodle_db_user \
    -e MYSQL_PASSWORD=$moodle_db_password \
    -d $mysql_image_name