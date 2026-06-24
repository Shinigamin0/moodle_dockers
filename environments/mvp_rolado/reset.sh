#!/bin/bash
source ./conf
docker stop $moodle_app_container_name
docker stop $moodle_db_container_name
docker stop phpmyadmin_rolado_db
docker stop phpmyadmin_posgrado_db
docker rm $moodle_app_container_name
docker rm $moodle_db_container_name
docker rm phpmyadmin_rolado_db
docker rm phpmyadmin_posgrado_db
#docker rmi $moodle_image_name
rm -rf app data db phpmyadmin
mkdir app data db