#!/bin/bash
source ./conf
echo $moodle_name
if [ "$(docker container inspect -f '{{.State.Status}}' $moodle_app_container_name)" == "running" ];
then
    echo "Iniciando proceso de instalación..."
    docker exec -it $moodle_app_container_name /bin/bash -c 'su - www-data -c "/var/www/install_moodle.sh $moodle_name" -s /bin/bash'
    docker exec -it $moodle_app_container_name /bin/bash -c '/var/www/install_permissions.sh'
else
    echo "$moodle_app_container_name aun no arranca..."
fi


