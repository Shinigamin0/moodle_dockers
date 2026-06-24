#!/bin/bash
set -e # Protección contra errores silenciosos

export DEBIAN_FRONTEND=noninteractive

echo "Instalando Apache2..."

apt-get install -y apache2

a2enmod rewrite
a2enmod headers

# Ajuste crítico para Moodle 5.0+: Apuntar el DocumentRoot a la carpeta public/
sed -i 's|DocumentRoot /var/www/html|DocumentRoot /var/www/html/public|g' /etc/apache2/sites-available/000-default.conf

ln -sf /dev/stdout /var/log/apache2/access.log
ln -sf /dev/stderr /var/log/apache2/error.log

apt-get clean
rm -rf /var/lib/apt/lists/*

echo "Instalación y configuración de Apache completadas."