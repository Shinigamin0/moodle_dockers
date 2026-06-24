#!/bin/bash
source ./conf
echo "Construyendo imagen..."
docker build \
    --build-arg moodle_version=$moodle_version \
    --build-arg moodle_tag=$moodle_tag \
    --build-arg php_version=$php_version \
    -t $moodle_image_name ./image/.
echo "Creando red..."
docker network create $moodle_docker_network
echo "Creando volumenes..."
mkdir db data
