#!/bin/bash

source ./conf

echo "Creando red..."
docker network create $moodle_docker_network

echo "Creando volumenes..."
mkdir -p db data1 data2

echo "Desplegando MySql "

docker pull $mysql_image_name

docker run \
    --network=$moodle_docker_network \
    -p $moodle_db_port:3306 \
    --name $moodle_db_1_container_name \
    -v $(pwd)/db:/var/lib/mysql \
    -e MYSQL_ROOT_PASSWORD=$mysql_root_password \
    -e MYSQL_DATABASE=$moodle_db_name \
    -e MYSQL_USER=$moodle_db_user \
    -e MYSQL_PASSWORD=$moodle_db_password \
    -d $mysql_image_name

echo "Desplegando Moodle Principal"

docker run \
    --env moodle_name=$moodle_1_name \
    --network=$moodle_docker_network \
    -p $moodle_app_1_port:80 \
    --name $moodle_1_app_container_name \
    -v $(pwd)/data1:/var/www/moodledata \
    -d moodle:$moodle_version

sleep 15

echo "Instalando Moodle Principal"

if [ "$(docker container inspect -f '{{.State.Status}}' $moodle_1_app_container_name)" == "running" ];
then
    echo "Iniciando proceso de instalación..."
    
    docker exec -it $moodle_1_app_container_name /bin/bash -c "su - www-data -s /bin/bash -c '/var/www/install_moodle.sh $moodle_db_1_container_name $moodle_db_name $moodle_db_user $moodle_db_password $moodle_db_port http://localhost:$moodle_app_1_port $app_user $app_password'"
    
    docker exec -it $moodle_1_app_container_name /bin/bash -c '/var/www/set_permissions.sh'
else
    echo "$moodle_1_app_container_name aun no arranca..."
    exit 1
fi

echo "Creando usuario API (solo lectura) en la base de datos..."

docker exec -i $moodle_db_1_container_name mysql -uroot -p"$mysql_root_password" -e "
    CREATE USER IF NOT EXISTS '${moodle_db_readonly_user}'@'%' IDENTIFIED BY '${moodle_db_readonly_password}';
    GRANT SELECT ON ${moodle_db_name}.* TO '${moodle_db_readonly_user}'@'%';
    GRANT INSERT, UPDATE, DELETE ON ${moodle_db_name}.mdl_sessions TO '${moodle_db_readonly_user}'@'%';
    GRANT INSERT, UPDATE, DELETE ON ${moodle_db_name}.mdl_logstore_standard_log TO '${moodle_db_readonly_user}'@'%';
    GRANT INSERT, UPDATE, DELETE ON ${moodle_db_name}.mdl_external_tokens TO '${moodle_db_readonly_user}'@'%';
    FLUSH PRIVILEGES;
"

echo "Preparando configuración de Enrutamiento de Base de Datos para el nodo API..."

docker cp $moodle_1_app_container_name:/var/www/html/config.php ./config_api.php

# 2. Ajustamos la URL base para que apunte al puerto/dominio de la API
sed -i "s|:$moodle_app_1_port|:$moodle_app_2_port|g" ./config_api.php

cat << EOF >> ./config_api.php

// ========================================================================
// CONFIGURACIÓN DE REPLICA DE LECTURA (API NODE)
// ========================================================================
\$CFG->dboptions['readonly'] = [
    'instance' => [
        [
            'dbhost' => '${moodle_db_1_container_name}', 
            'dbport' => '${moodle_db_port}',
            'dbuser' => '${moodle_db_readonly_user}',
            'dbpass' => '${moodle_db_readonly_password}'
        ]
    ]
];
EOF

echo "Desplegando Moodle API"

cp -r data1/* data2/

docker run \
    --env moodle_name=$moodle_2_name \
    --network=$moodle_docker_network \
    -p $moodle_app_2_port:80 \
    --name $moodle_2_app_container_name \
    -v $(pwd)/data2:/var/www/moodledata \
    -d moodle:$moodle_version

docker cp ./config_api.php $moodle_2_app_container_name:/var/www/html/config.php

docker exec -it $moodle_2_app_container_name chown root:www-data /var/www/html/config.php
docker exec -it $moodle_2_app_container_name chmod 640 /var/www/html/config.php
rm ./config_api.php

echo "Despliegue de nodo API con Read/Write Splitting completado."