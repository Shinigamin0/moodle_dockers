docker run --name phpmyadmin_posgrado_db --network moodle -v phpmyadmin:/etc/phpmyadmin/config.usr.inc.php --link posgrado_db:db -p 81:80 -d phpmyadmin/phpmyadmin
#localhost:81