docker run --name phpmyadmin_rolado_db --network moodle -v phpmyadmin:/etc/phpmyadmin/config.usr.inc.php --link rolado_db:db -p 82:80 -d phpmyadmin/phpmyadmin