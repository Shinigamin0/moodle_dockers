#!/bin/bash
source ./conf

SEP="═══════════════════════════════════════════════════════════════════"

QUERY="SELECT event_time, user_host, CONVERT(argument USING utf8) AS query
FROM mysql.general_log
WHERE command_type = 'Query'
ORDER BY event_time DESC
LIMIT 30;"

echo ""
echo "$SEP"
echo "  MOTOR DE ESCRITURA: $moodle_db_1_container_name"
echo "$SEP"
docker exec -i $moodle_db_1_container_name \
    mysql -uroot -p"$mysql_root_password" --table -e "$QUERY" 2>/dev/null

echo ""
echo "$SEP"
echo "  MOTOR DE LECTURA:   $moodle_db_2_container_name"
echo "$SEP"
docker exec -i $moodle_db_2_container_name \
    mysql -uroot -p"$mysql_root_password" --table -e "$QUERY" 2>/dev/null

echo ""
