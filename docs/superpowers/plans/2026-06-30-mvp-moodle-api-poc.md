# POC Moodle API — Plan de Implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Corregir los 8 bugs del ambiente POC y reescribir `log.sh` para evidenciar visualmente el read/write splitting entre `principal_db` y `api_db`.

**Architecture:** Cinco scripts Bash en `environments/mvp_moodle_api/`. Los cambios son independientes entre sí salvo que todos leen variables de `conf`. No se modifica `conf` ni los archivos de `images/`.

**Tech Stack:** Bash, Docker CLI, MySQL 8.4 (`mysql.general_log`)

## Global Constraints

- Todos los scripts deben tener `#!/bin/bash` como primera línea
- Todos los scripts que usen variables de configuración deben comenzar con `source ./conf` inmediatamente después del shebang
- Ningún script puede tener nombres de contenedores, contraseñas o puertos hardcodeados — siempre usar variables de `conf`
- `docker exec` en scripts no interactivos: flag `-i` únicamente, nunca `-it`
- Los archivos en `images/` están fuera de scope — no tocar

---

## Mapa de archivos

| Archivo | Acción | Cambios |
|---|---|---|
| `environments/mvp_moodle_api/deploy.sh` | Modificar | Eliminar override de variable, `-it`→`-i`, corregir hardcodes, añadir check de imagen |
| `environments/mvp_moodle_api/teardown.sh` | Modificar | Añadir replica y phpmyadmin a stop/rm, corregir `docker rmi` hardcodeado |
| `environments/mvp_moodle_api/replication_test.sh` | Modificar | Añadir shebang + `source ./conf` + reemplazar hardcodes |
| `environments/mvp_moodle_api/phpmyadmin.sh` | Modificar | Añadir shebang |
| `environments/mvp_moodle_api/log.sh` | Reescribir | Evidencia visual de ambos motores |

---

## Task 1: Corregir `deploy.sh`

**Files:**
- Modify: `environments/mvp_moodle_api/deploy.sh`

**Interfaces:**
- Consumes: variables de `conf` — `$moodle_db_1_container_name`, `$moodle_db_2_container_name`, `$mysql_root_password`, `$moodle_version`
- Produces: despliegue funcional sin sobreescritura de variables ni flags incorrectos

- [ ] **Step 1: Eliminar el override de `moodle_db_2_container_name` (línea 36)**

Abrir `environments/mvp_moodle_api/deploy.sh` y eliminar esta línea:

```bash
moodle_db_2_container_name="replica_db"
```

La variable ya está correctamente definida en `conf` como `$moodle_2_name"_db"` (= `api_db`). Esta línea la pisaba silenciosamente.

- [ ] **Step 2: Corregir los nombres hardcodeados en el bloque de activación de logs (líneas 56-59)**

Antes:
```bash
# Encender log en el Motor de Escritura (Master)
docker exec -it principal_db mysql -uroot -prootPassword -e "SET GLOBAL log_output = 'TABLE'; SET GLOBAL general_log = 'ON';"

# Encender log en el Motor de Lectura (Replica)
docker exec -it replica_db mysql -uroot -prootPassword -e "SET GLOBAL log_output = 'TABLE'; SET GLOBAL general_log = 'ON';"
```

Después:
```bash
# Encender log en el Motor de Escritura (Master)
docker exec -i $moodle_db_1_container_name mysql -uroot -p"$mysql_root_password" -e "SET GLOBAL log_output = 'TABLE'; SET GLOBAL general_log = 'ON';"

# Encender log en el Motor de Lectura (Replica)
docker exec -i $moodle_db_2_container_name mysql -uroot -p"$mysql_root_password" -e "SET GLOBAL log_output = 'TABLE'; SET GLOBAL general_log = 'ON';"
```

- [ ] **Step 3: Cambiar todos los `docker exec -it` restantes a `docker exec -i`**

Aplicar el cambio a cada una de estas líneas (buscar con `grep -n "docker exec -it" deploy.sh`):

```bash
# Línea ~29 — configurar usuario de replicación en master
docker exec -i $moodle_db_1_container_name mysql -uroot -p"$mysql_root_password" -e "..."

# Línea ~50 — vincular replica al master
docker exec -i $moodle_db_2_container_name mysql -uroot -p"$mysql_root_password" -e "..."

# Línea ~79 — chown temporal para instalación
docker exec -i $moodle_1_app_container_name chown -R www-data:www-data /var/www/html/

# Línea ~84 — instalación Moodle CLI
if ! docker exec -i $moodle_1_app_container_name /bin/bash -c "su - www-data -s /bin/bash -c '/usr/local/bin/install_moodle.sh ...'"; then

# Línea ~90 — restaurar permisos
docker exec -i $moodle_1_app_container_name /usr/local/bin/set_permissions.sh

# Línea ~146 — permisos config API
docker exec -i $moodle_2_app_container_name chown root:www-data /var/www/html/config.php
docker exec -i $moodle_2_app_container_name chmod 640 /var/www/html/config.php
```

Verificar que no queda ninguno:
```bash
grep -n "docker exec -it" environments/mvp_moodle_api/deploy.sh
```
Resultado esperado: sin output (cero ocurrencias).

- [ ] **Step 4: Corregir `'dbhost'` hardcodeado en el bloque PHP (línea ~120)**

Antes:
```bash
            'dbhost' => 'replica_db',
```

Después:
```bash
            'dbhost' => '${moodle_db_2_container_name}',
```

Nota: la comilla simple del heredoc no evita la expansión de variables porque el heredoc se abrió con `<< EOF` (sin comillas). Las variables `${...}` sí se expanden; `\$CFG` está escapado correctamente para producir PHP literal.

- [ ] **Step 5: Añadir verificación de imagen al inicio del script**

Insertar después de `source ./conf` y antes del primer `echo`:

```bash
if ! docker image inspect moodle:$moodle_version &>/dev/null; then
    echo "❌ ERROR: La imagen moodle:$moodle_version no existe."
    echo "   Ejecuta primero: cd ../../images && ./build_${moodle_version}.sh"
    exit 1
fi
```

- [ ] **Step 6: Verificar el script con shellcheck**

```bash
shellcheck environments/mvp_moodle_api/deploy.sh
```

Si `shellcheck` no está instalado: `brew install shellcheck`. Corregir cualquier warning de nivel `error`.

- [ ] **Step 7: Commit**

```bash
git add environments/mvp_moodle_api/deploy.sh
git commit -m "fix(deploy): corregir override de variable, flags -it y hardcodes"
```

---

## Task 2: Corregir `teardown.sh`

**Files:**
- Modify: `environments/mvp_moodle_api/teardown.sh`

**Interfaces:**
- Consumes: `$moodle_1_app_container_name`, `$moodle_2_app_container_name`, `$moodle_db_1_container_name`, `$moodle_db_2_container_name`, `$phpmyadmin_container_name`, `$moodle_version`
- Produces: limpieza completa de todos los contenedores del ambiente

- [ ] **Step 1: Añadir `$moodle_db_2_container_name` y corregir phpmyadmin en `docker stop`**

Antes:
```bash
docker stop \
    $moodle_1_app_container_name \
    $moodle_2_app_container_name \
    $moodle_db_1_container_name \
    phpmyadmin_rolado_db \
    phpmyadmin_posgrado_db 2>/dev/null || true
```

Después:
```bash
docker stop \
    $moodle_1_app_container_name \
    $moodle_2_app_container_name \
    $moodle_db_1_container_name \
    $moodle_db_2_container_name \
    $phpmyadmin_container_name 2>/dev/null || true
```

- [ ] **Step 2: Aplicar el mismo cambio a `docker rm`**

Antes:
```bash
docker rm \
    $moodle_1_app_container_name \
    $moodle_2_app_container_name \
    $moodle_db_1_container_name \
    phpmyadmin_rolado_db \
    phpmyadmin_posgrado_db 2>/dev/null || true
```

Después:
```bash
docker rm \
    $moodle_1_app_container_name \
    $moodle_2_app_container_name \
    $moodle_db_1_container_name \
    $moodle_db_2_container_name \
    $phpmyadmin_container_name 2>/dev/null || true
```

- [ ] **Step 3: Corregir `docker rmi` hardcodeado al final del script**

Antes (última línea):
```bash
docker rmi moodle:502
```

Después:
```bash
docker rmi moodle:$moodle_version 2>/dev/null || true
```

Se añade `2>/dev/null || true` para no fallar si la imagen no existe o está en uso.

- [ ] **Step 4: Verificar**

```bash
grep -n "rolado_db\|posgrado_db\|moodle:502" environments/mvp_moodle_api/teardown.sh
```

Resultado esperado: sin output.

- [ ] **Step 5: Commit**

```bash
git add environments/mvp_moodle_api/teardown.sh
git commit -m "fix(teardown): añadir replica y phpmyadmin a limpieza, corregir docker rmi"
```

---

## Task 3: Corregir `replication_test.sh` y `phpmyadmin.sh`

**Files:**
- Modify: `environments/mvp_moodle_api/replication_test.sh`
- Modify: `environments/mvp_moodle_api/phpmyadmin.sh`

**Interfaces:**
- Consumes: `$moodle_db_1_container_name`, `$moodle_db_2_container_name`, `$mysql_root_password`
- Produces: scripts ejecutables con variables del conf

- [ ] **Step 1: Reescribir `replication_test.sh` completo**

Reemplazar el contenido completo del archivo con:

```bash
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
```

- [ ] **Step 2: Añadir shebang a `phpmyadmin.sh`**

Insertar `#!/bin/bash` como primera línea del archivo. El resto del contenido no cambia.

Archivo completo resultante:
```bash
#!/bin/bash
echo "Desplegando phpMyAdmin para administración de Base de Datos..."

docker run \
    --name $phpmyadmin_container_name \
    --network=$moodle_docker_network \
    -p $phpmyadmin_port:80 \
    -e PMA_HOST=$moodle_db_1_container_name \
    -e MYSQL_ROOT_PASSWORD=$mysql_root_password \
    -d phpmyadmin/phpmyadmin

echo "phpMyAdmin desplegado. Acceso en: http://localhost:$phpmyadmin_port"
```

Nota: `phpmyadmin.sh` no necesita `source ./conf` porque es llamado desde el directorio del ambiente con las variables ya cargadas en el contexto del deploy, pero sí se ejecuta con `./phpmyadmin.sh` de forma independiente — en ese caso las variables no estarán. Añadir `source ./conf` es la práctica correcta.

Archivo completo corregido:
```bash
#!/bin/bash
source ./conf

echo "Desplegando phpMyAdmin para administración de Base de Datos..."

docker run \
    --name $phpmyadmin_container_name \
    --network=$moodle_docker_network \
    -p $phpmyadmin_port:80 \
    -e PMA_HOST=$moodle_db_1_container_name \
    -e MYSQL_ROOT_PASSWORD=$mysql_root_password \
    -d phpmyadmin/phpmyadmin

echo "phpMyAdmin desplegado. Acceso en: http://localhost:$phpmyadmin_port"
```

- [ ] **Step 3: Verificar shebangs**

```bash
head -1 environments/mvp_moodle_api/replication_test.sh
head -1 environments/mvp_moodle_api/phpmyadmin.sh
```

Resultado esperado (ambos):
```
#!/bin/bash
```

- [ ] **Step 4: Verificar que no quedan hardcodes en `replication_test.sh`**

```bash
grep -n "principal_db\|replica_db\|rootPassword" environments/mvp_moodle_api/replication_test.sh
```

Resultado esperado: sin output.

- [ ] **Step 5: Commit**

```bash
git add environments/mvp_moodle_api/replication_test.sh environments/mvp_moodle_api/phpmyadmin.sh
git commit -m "fix(scripts): añadir shebang y source conf a replication_test y phpmyadmin"
```

---

## Task 4: Reescribir `log.sh` — evidencia visual del read/write splitting

**Files:**
- Modify: `environments/mvp_moodle_api/log.sh`

**Interfaces:**
- Consumes: `$moodle_db_1_container_name`, `$moodle_db_2_container_name`, `$mysql_root_password`
- Produces: output visual en terminal con queries de cada motor, separadas por secciones con separadores

- [ ] **Step 1: Reemplazar el contenido completo de `log.sh`**

```bash
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
```

El flag `--table` imprime el resultado con bordes ASCII, haciendo la tabla legible en terminal sin necesidad de formateo adicional.

- [ ] **Step 2: Dar permisos de ejecución**

```bash
chmod +x environments/mvp_moodle_api/log.sh
```

- [ ] **Step 3: Verificar que no quedan hardcodes**

```bash
grep -n "principal_db\|replica_db\|rootPassword\|Password" environments/mvp_moodle_api/log.sh
```

Resultado esperado: sin output.

- [ ] **Step 4: Smoke test del script (requiere el ambiente desplegado)**

Si el ambiente está corriendo:

```bash
cd environments/mvp_moodle_api && ./log.sh
```

Resultado esperado:
```
═══════════════...
  MOTOR DE ESCRITURA: principal_db
═══════════════...
+---------------------+--------------------+-----------------------------+
| event_time          | user_host          | query                       |
+---------------------+--------------------+-----------------------------+
| 2026-06-30 10:01:23 | user[user]@%       | INSERT INTO mdl_sessions... |
...

═══════════════...
  MOTOR DE LECTURA:   api_db
═══════════════...
+---------------------+------------------------+---------------------------+
| event_time          | user_host              | query                     |
+---------------------+------------------------+---------------------------+
| 2026-06-30 10:01:25 | readonly[readonly]@%   | SELECT * FROM mdl_user... |
...
```

Si el ambiente no está corriendo, verificar solo la sintaxis:
```bash
bash -n environments/mvp_moodle_api/log.sh && echo "Sintaxis OK"
```

- [ ] **Step 5: Commit**

```bash
git add environments/mvp_moodle_api/log.sh
git commit -m "feat(log): reescribir evidencia visual de read/write splitting"
```

---

## Criterio de éxito del plan

Tras ejecutar los 4 tasks:

```bash
# Ningún -it en los scripts
grep -rn "docker exec -it" environments/mvp_moodle_api/
# → sin output

# Ningún hardcode de nombres de contenedores o passwords
grep -rn "principal_db\|replica_db\|rootPassword" environments/mvp_moodle_api/*.sh
# → sin output

# Todos los scripts tienen shebang
head -1 environments/mvp_moodle_api/*.sh
# → todos muestran #!/bin/bash
```
