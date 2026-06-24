#!/bin/bash

# Cargar las variables de entorno
source ./conf

echo "Iniciando limpieza del ambiente Moodle..."

# 1. Detener contenedores
echo "Deteniendo contenedores..."
docker stop \
    $moodle_1_app_container_name \
    $moodle_2_app_container_name \
    $moodle_db_1_container_name \
    phpmyadmin_rolado_db \
    phpmyadmin_posgrado_db 2>/dev/null || true

# 2. Eliminar contenedores
echo "Eliminando contenedores..."
docker rm \
    $moodle_1_app_container_name \
    $moodle_2_app_container_name \
    $moodle_db_1_container_name \
    phpmyadmin_rolado_db \
    phpmyadmin_posgrado_db 2>/dev/null || true

# 3. Eliminar la red compartida
echo "Eliminando red de Docker..."
docker network rm $moodle_docker_network 2>/dev/null || true

# OPCIONAL: Eliminar imagen (Descomentar si necesitas forzar un rebuild desde cero)
# docker rmi moodle:$moodle_version 2>/dev/null || true

# 4. Limpiar directorios de volúmenes físicos
echo "Purgando directorios de datos (Se requiere contraseña sudo si hay archivos bloqueados)..."
# Se agregan data1 y data2 que son los que usa tu script de deploy actual
sudo rm -rf app data db data1 data2 phpmyadmin

# 5. Recrear estructura base
echo "Recreando estructura de carpetas..."
mkdir -p app data db data1 data2 phpmyadmin

echo "¡Ambiente limpio y listo para un nuevo despliegue!"