#!/bin/bash

echo "Ajustando permisos seguros para Moodle..."

# 1. Asegurar el código fuente de Moodle (html)
# El usuario root es el dueño, pero el grupo web puede leer.
chown -R root:www-data /var/www/html/

# Directorios con permisos 755 (rwxr-xr-x) y archivos con 644 (rw-r--r--)
# Esto impide que www-data modifique el código base.
find /var/www/html/ -type d -exec chmod 755 {} \;
find /var/www/html/ -type f -exec chmod 644 {} \;

# 2. Asegurar el directorio de datos (moodledata)
# Moodle DEBE escribir aquí.
chown -R www-data:www-data /var/www/moodledata/

# Permisos 770 (rwxrwx---) asegura que solo el propietario (www-data) 
# y el grupo (www-data) puedan acceder, bloqueando al resto de usuarios del sistema.
chmod -R 770 /var/www/moodledata/

echo "Permisos aplicados correctamente."