#!/bin/bash
echo "Desplegando MySql"
docker pull $mysql_image_name
docker run --network=moodle -p 3307:3306 --name rolado_db -v $(pwd)/db:/var/lib/mysql -e MYSQL_ROOT_PASSWORD="password" -e MYSQL_DATABASE='rolado' -e MYSQL_USER='rolado' -e MYSQL_PASSWORD='password' -d mysql:8.0.29