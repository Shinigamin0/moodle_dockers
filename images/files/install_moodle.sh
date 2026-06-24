#!/bin/bash

# Recibir los parámetros desde el script de deploy
DB_HOST=$1
DB_NAME=$2
DB_USER=$3
DB_PASS=$4
DB_PORT=$5
APP_URL=$6
ADMIN_USER=$7
ADMIN_PASS=$8
ADMIN_EMAIL=$9

echo "Configurando Moodle con los siguientes parámetros:"
echo "DB_HOST: ${DB_HOST}"
echo "APP_URL: ${APP_URL}"

# Ejecutar el instalador CLI de Moodle
/usr/bin/php /var/www/html/admin/cli/install.php \
    --lang=es \
    --wwwroot="${APP_URL}" \
    --dataroot=/var/www/moodledata \
    --dbhost="${DB_HOST}" \
    --dbname="${DB_NAME}" \
    --dbuser="${DB_USER}" \
    --dbpass="${DB_PASS}" \
    --dbport="${DB_PORT}" \
    --fullname="Moodle Institucional UNIMINUTO" \
    --shortname="Moodle" \
    --summary="Plataforma principal" \
    --adminuser="${ADMIN_USER}" \
    --adminpass="${ADMIN_PASS}" \
    --adminemail="${ADMIN_EMAIL}" \
    --non-interactive \
    --agree-license

echo "Instalación de la base de datos de Moodle finalizada."