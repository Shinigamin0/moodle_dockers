echo "Desplegando phpMyAdmin para administración de Base de Datos..."

docker run \
    --name $phpmyadmin_container_name \
    --network=$moodle_docker_network \
    -p $phpmyadmin_port:80 \
    -e PMA_HOST=$moodle_db_1_container_name \
    -e MYSQL_ROOT_PASSWORD=$mysql_root_password \
    -d phpmyadmin/phpmyadmin

echo "phpMyAdmin desplegado. Acceso en: http://localhost:$phpmyadmin_port"