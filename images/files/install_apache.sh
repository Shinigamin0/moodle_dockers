#!/bin/bash

# Asegurar que no haya prompts interactivos que detengan el build
export DEBIAN_FRONTEND=noninteractive

echo "Instalando Apache2..."

# 1. El flag -y es obligatorio en Docker para automatizar la instalación
apt-get install -y apache2

# 2. Habilitar módulos de Apache clave para Moodle y seguridad
a2enmod rewrite   # Necesario para que funcionen las "URLs limpias" en Moodle
a2enmod headers   # Permite configurar cabeceras de seguridad en el virtual host

# 3. Redirigir los logs a la salida estándar (Buenas prácticas de Docker)
# Esto permite que el comando `docker logs <nombre_contenedor>` funcione correctamente
ln -sf /dev/stdout /var/log/apache2/access.log
ln -sf /dev/stderr /var/log/apache2/error.log

# 4. Limpieza profunda para reducir el peso de la imagen
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "Instalación y configuración de Apache completadas."