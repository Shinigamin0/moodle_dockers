#!/bin/bash

# CRÍTICO: Detener el script si cualquier comando falla
set -e

PHP_VERSION=$1

if [ -z "$PHP_VERSION" ]; then
    echo "Error: Se requiere especificar la versión de PHP."
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo "Iniciando instalación de PHP ${PHP_VERSION}..."

apt-get update
apt-get install -y software-properties-common apt-transport-https ca-certificates

add-apt-repository ppa:ondrej/php -y
apt-get update

# Instalar PHP y módulos. 
# NOTA: imagick ahora tiene la variable de versión para no traer PHP 8.5 por error.
apt-get install -y \
php${PHP_VERSION} \
libapache2-mod-php${PHP_VERSION} \
php${PHP_VERSION}-common \
php${PHP_VERSION}-mysql \
php${PHP_VERSION}-pgsql \
php${PHP_VERSION}-snmp \
php${PHP_VERSION}-ldap \
php${PHP_VERSION}-xml \
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
php${PHP_VERSION}-imagick

# BLINDAJE 1: Forzar a Ubuntu a usar nuestra versión de PHP como el comando 'php' por defecto
update-alternatives --set php /usr/bin/php${PHP_VERSION}

# BLINDAJE 2: Forzar la habilitación de todos los módulos usando sus nombres internos correctos
phpenmod -v ${PHP_VERSION} -s ALL curl mysqli pdo_mysql pgsql snmp ldap xml gd imap mbstring opcache soap zip intl imagick

apt-get clean
rm -rf /var/lib/apt/lists/*

if [ -d "/etc/php/${PHP_VERSION}/apache2" ]; then
    echo 'max_input_vars = 5000' >> /etc/php/${PHP_VERSION}/apache2/php.ini
fi

if [ -d "/etc/php/${PHP_VERSION}/cli" ]; then
    echo 'max_input_vars = 5000' >> /etc/php/${PHP_VERSION}/cli/php.ini
fi

echo "Instalación de PHP ${PHP_VERSION} completada con éxito."