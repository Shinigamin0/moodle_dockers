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
    echo "Desbloqueando permisos temporalmente para la instalación..."
    docker exec -it $moodle_1_app_container_name chown -R www-data:www-data /var/www/html/

    echo "Iniciando proceso de instalación..."
    
    # Envolvemos el comando en un IF para abortar todo si Moodle falla al instalarse
    if ! docker exec -it $moodle_1_app_container_name /bin/bash -c "su - www-data -s /bin/bash -c '/usr/local/bin/install_moodle.sh $moodle_db_1_container_name $moodle_db_name $moodle_db_user $moodle_db_password $moodle_db_port http://localhost:$moodle_app_1_port $app_user $app_password $app_email'"; then
        echo "❌ ERROR: La instalación de Moodle falló. Abortando despliegue para evitar base de datos corrupta."
        exit 1
    fi
    
    echo "Restaurando blindaje de permisos seguros..."
    docker exec -it $moodle_1_app_container_name /usr/local/bin/set_permissions.sh
else
    echo "❌ ERROR: $moodle_1_app_container_name aun no arranca..."
    exit 1
fi

sleep 15 

echo "Creando usuario API (solo lectura) en la base de datos..."
# Simplificado a SELECT global. Sin dependencia de tablas que puedan romper el script.
docker exec -i $moodle_db_1_container_name mysql -uroot -p"$mysql_root_password" -e "
    CREATE USER IF NOT EXISTS '${moodle_db_readonly_user}'@'%' IDENTIFIED BY '${moodle_db_readonly_password}';
    GRANT SELECT ON ${moodle_db_name}.* TO '${moodle_db_readonly_user}'@'%';
    FLUSH PRIVILEGES;
"

echo "Preparando configuración de Enrutamiento de Base de Datos para el nodo API..."

docker cp $moodle_1_app_container_name:/var/www/html/config.php ./config_api.php

sed -i.bak "s|:$moodle_app_1_port|:$moodle_app_2_port|g" ./config_api.php
rm -f ./config_api.php.bak

cat << EOF >> ./config_api.php

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