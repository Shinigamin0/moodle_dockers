#!/bin/bash

# Cargar las variables de entorno
source ./conf

echo "Iniciando la ejecución del cron en el Moodle Principal ($moodle_1_app_container_name)..."

# Ejecutar el cron usando su ruta absoluta y el usuario www-data
docker exec -i $moodle_1_app_container_name su - www-data -s /bin/bash -c "/usr/bin/php /var/www/html/admin/cli/cron.php"

echo "Cron del Moodle Principal ejecutado con éxito."