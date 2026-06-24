#!/bin/bash
echo "Configurando Moodle con los siguientes parámetros:"
echo "DB_HOST: "$moodle_name"_db"
/usr/bin/php /var/www/html/admin/cli/install.php \
    --lang=en --wwwroot=http://localhost \
    --dataroot=/var/www/moodledata \
    --dbhost=$moodle_name"_db" --dbname="moodle" --dbuser="user" --dbpass='password' --dbport="3306" \
    --fullname=$moodle_name --shortname=$moodle_name --summary=$moodle_name \
    --adminuser="administrador" --adminpass="administrador" --adminemail="admin@admin.com" \
    --non-interactive --agree-license

