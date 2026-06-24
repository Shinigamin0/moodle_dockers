docker exec -it principal_db mysql -uroot -prootPassword -e "
    SET GLOBAL log_output = 'TABLE';
    SET GLOBAL general_log = 'ON';
"

docker exec -it principal_db mysql -uroot -prootPassword -e "
    CREATE USER IF NOT EXISTS 'readonly'@'%' IDENTIFIED BY 'Password';
    GRANT SELECT ON moodle.* TO 'readonly'@'%';
    FLUSH PRIVILEGES;
"

docker exec -it principal_db mysql -uroot -prootPassword -e "
    SELECT event_time, argument
    FROM mysql.general_log
    WHERE user_host LIKE 'user%' AND command_type = 'Query'
    ORDER BY event_time DESC LIMIT 10;
"

docker exec -it principal_db mysql -uroot -prootPassword -e "
    SELECT event_time, CONVERT(argument USING utf8) AS query
    FROM mysql.general_log
    WHERE user_host LIKE 'readonly%' AND command_type = 'Query'
    ORDER BY event_time DESC LIMIT 10;
"