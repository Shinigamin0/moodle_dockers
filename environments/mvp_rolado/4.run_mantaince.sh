#!/bin/bash
source ./conf
docker exec -it $moodle_app_container_name /bin/bash -c 'su - www-data -c "php /var/www/html/admin/cli/cron.php" -s /bin/bash'