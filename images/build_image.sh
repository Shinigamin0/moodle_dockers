#!/bin/bash

MOODLE_VERSION=$1
MOODLE_TAG=$2
PHP_VERSION=$3

# Validación: Comprobar que se hayan pasado exactamente 3 parámetros
if [ "$#" -ne 3 ]; then
    echo "Error: Faltan parámetros."
    echo "Uso correcto: $0 <moodle_version> <moodle_tag> <php_version>"
    echo "Ejemplo:      $0 502 5.0.2 8.4"
    exit 1
fi

echo "Construyendo imagen Moodle ${MOODLE_VERSION} (Tag: ${MOODLE_TAG}) con PHP ${PHP_VERSION}..."

docker build --no-cache \
    --build-arg moodle_version=${MOODLE_VERSION} \
    --build-arg moodle_tag=${MOODLE_TAG} \
    --build-arg php_version=${PHP_VERSION} \
    -t moodle:${MOODLE_VERSION} ./files