#!/bin/bash

# Recibir la variable pasada desde el Dockerfile
PHP_VERSION=$1

if [ -z "$PHP_VERSION" ]; then
    echo "Error: Se requiere especificar la versión de PHP."
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo "Iniciando instalación de PHP ${PHP_VERSION}..."

# Asegurar dependencias previas (ya instaladas en install_tools.sh, pero por seguridad)
apt-get update
apt-get install -y software-properties-common apt-transport-https ca-certificates

# Agregar el PPA de Ondřej Surý
add-apt-repository ppa:ondrej/php -y
apt-get update

# Instalar PHP y todos los módulos requeridos por Moodle
apt-get install -y \
php${PHP_VERSION} \
libapache2-mod-php${PHP_VERSION} \
php${PHP_VERSION}-common \
php${PHP_VERSION}-mysql \
php${PHP_VERSION}-pgsql \
php${PHP_VERSION}-snmp \
php${PHP_VERSION}-ldap \
php${PHP_VERSION}-xml \
php${PHP_VERSION}-xmlrpc \
php${PHP_VERSION}-curl \
php${PHP_VERSION}-gd \
php${PHP_VERSION}-cli \
php${PHP_VERSION}-dev \
php${PHP_VERSION}-imap \
php${PHP_VERSION}-mbstring \
php${PHP_VERSION}-opcache \
php${PHP_VERSION}-soap \
php${PHP_VERSION}-zip \
php${PHP_VERSION}-intl \
php-imagick

# Limpiar caché de apt
apt-get clean
rm -rf /var/lib/apt/lists/*

# Ajustar variables en el php.ini de Apache
if [ -d "/etc/php/${PHP_VERSION}/apache2" ]; then
    echo 'max_input_vars = 5000' >> /etc/php/${PHP_VERSION}/apache2/php.ini
fi

echo "Instalación de PHP ${PHP_VERSION} completada con éxito."