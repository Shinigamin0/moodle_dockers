#!/bin/bash
source ./conf

echo "Insertando datos de prueba en el master ($moodle_db_1_container_name)..."
docker exec -i $moodle_db_1_container_name mysql -uroot -p"$mysql_root_password" -e "
    CREATE DATABASE IF NOT EXISTS test_replicacion;
    USE test_replicacion;
    CREATE TABLE IF NOT EXISTS mensajes (
        id INT AUTO_INCREMENT PRIMARY KEY,
        texto VARCHAR(100),
        fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    INSERT INTO mensajes (texto) VALUES ('Este mensaje viajó del Master a la Réplica.');
    SELECT * FROM mensajes;
"

echo ""
echo "Verificando replicación en la réplica ($moodle_db_2_container_name)..."
docker exec -i $moodle_db_2_container_name mysql -uroot -p"$mysql_root_password" -e "
    SELECT * FROM test_replicacion.mensajes;
"
