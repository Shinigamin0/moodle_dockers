# Diseño: POC Moodle API con Read/Write Splitting

**Fecha:** 2026-06-30
**Ambiente:** `environments/mvp_moodle_api/`

---

## Objetivo

Demostrar que una instancia Moodle configurada como nodo API enruta correctamente:
- Operaciones de **escritura** (INSERT, UPDATE, DELETE) → MySQL master (`principal_db`)
- Operaciones de **lectura** (SELECT) → MySQL replica (`api_db`)

La evidencia se obtiene consultando `mysql.general_log` en ambos motores al final del despliegue.

---

## Arquitectura

```
                        ┌─────────────────────┐
                        │   mvp_moodle_api     │
                        │       network        │
                        └─────────┬───────────┘
                                  │
          ┌───────────────────────┼───────────────────────┐
          │                       │                       │
   ┌──────┴──────┐         ┌──────┴──────┐         ┌──────┴──────┐
   │ principal_app│         │   api_app   │         │ phpmyadmin  │
   │  (port 80)  │         │  (port 81)  │         │ (port 8080) │
   │  Moodle 5.x │         │  Moodle 5.x │         └─────────────┘
   └──────┬──────┘         └──────┬──────┘
          │ escritura              │ lectura (readonly user)
          │                       │
   ┌──────┴──────┐         ┌──────┴──────┐
   │ principal_db│──replica─▶│   api_db   │
   │  MySQL 8.4  │  GTID    │  MySQL 8.4 │
   │   (master)  │          │  (replica) │
   └─────────────┘          └────────────┘
```

**Contenedores:**

| Contenedor | Imagen | Puerto | Rol |
|---|---|---|---|
| `principal_app` | `moodle:502` | 80 | Moodle principal (R+W) |
| `api_app` | `moodle:502` | 81 | Moodle API (solo lectura en DB) |
| `principal_db` | `mysql:8.4.10` | — | MySQL master (escritura) |
| `api_db` | `mysql:8.4.10` | — | MySQL replica (lectura) |
| `phpmyadmin_moodle` | `phpmyadmin/phpmyadmin` | 8080 | Admin visual del master |

**Red Docker:** `mvp_moodle_api_network`

---

## Mecanismo de Read/Write Splitting

La instancia `api_app` usa la configuración nativa de Moodle `$CFG->dboptions['readonly']` en su `config.php`:

```php
$CFG->dboptions['readonly'] = [
    'instance' => [
        [
            'dbhost' => 'api_db',
            'dbport' => '3306',
            'dbuser' => 'readonly',
            'dbpass' => '<password>'
        ]
    ]
];
```

Con esta configuración, el DBI de Moodle envía automáticamente:
- Todas las queries de escritura → `principal_db` (conexión principal)
- Todas las queries de lectura → `api_db` (instancia readonly)

---

## Usuarios de base de datos

| Usuario | Permisos | Usado por |
|---|---|---|
| `user` | ALL en `moodle.*` | `principal_app` (R+W) |
| `readonly` | SELECT en `moodle.*` | `api_app` (solo lectura) |
| `replicator` | REPLICATION SLAVE | Replicación GTID |
| `root` | Superusuario | Scripts de administración |

---

## Flujo de despliegue (`deploy.sh`)

1. Crear red Docker
2. Levantar `principal_db` (master, GTID ON, server-id=1)
3. Crear usuario `replicator` en master
4. Levantar `api_db` (replica, GTID ON, server-id=2)
5. Vincular replica al master con `CHANGE REPLICATION SOURCE`
6. Habilitar `general_log` en ambos motores
7. Levantar `principal_app` y ejecutar instalación Moodle CLI
8. Crear usuario `readonly` en master (se replica automáticamente a `api_db`)
9. Generar `config.php` para `api_app` con readonly config
10. Copiar `moodledata` de instancia 1 a instancia 2
11. Levantar `api_app` e inyectar `config.php`

---

## Mecanismo de evidencia (`log.sh`)

Consulta `mysql.general_log` en ambos motores y muestra todas las queries ordenadas por tiempo:

```
═══════════════════════════════════════════════════════════
  MOTOR DE ESCRITURA: principal_db
═══════════════════════════════════════════════════════════
event_time           | user_host              | query
...INSERT, UPDATE, DELETE + SELECTs del usuario 'user'...

═══════════════════════════════════════════════════════════
  MOTOR DE LECTURA: api_db
═══════════════════════════════════════════════════════════
event_time           | user_host              | query
...solo SELECTs del usuario 'readonly'...
```

El contraste visual demuestra el splitting: en `api_db` solo aparece el usuario `readonly` con SELECTs, nunca escrituras.

Query ejecutada en cada motor:
```sql
SELECT event_time, user_host, CONVERT(argument USING utf8) AS query
FROM mysql.general_log
WHERE command_type = 'Query'
ORDER BY event_time DESC
LIMIT 30;
```

---

## Bugs corregidos

| # | Archivo | Problema | Fix |
|---|---|---|---|
| 1 | `deploy.sh:36` | `moodle_db_2_container_name` hardcodeado como `replica_db`, pisando la variable de `conf` | Eliminar línea 36; usar la variable del conf en todo el script |
| 2 | `deploy.sh:51,59` | Nombre `replica_db` literal en comandos docker | Reemplazar por `$moodle_db_2_container_name` |
| 3 | `deploy.sh:120` | `'dbhost' => 'replica_db'` hardcodeado en bloque PHP | Usar `${moodle_db_2_container_name}` |
| 4 | `deploy.sh` múltiples líneas | `docker exec -it` en script no interactivo | Cambiar a `docker exec -i` |
| 5 | `log.sh` | Sin shebang, sin `source ./conf`, credenciales hardcodeadas | Añadir shebang + source + variables |
| 6 | `replication_test.sh` | Sin shebang, sin `source ./conf`, credenciales hardcodeadas | Añadir shebang + source + variables |
| 7 | `phpmyadmin.sh` | Sin shebang | Añadir `#!/bin/bash` |
| 8 | `teardown.sh` | No elimina `$moodle_db_2_container_name`; referencias a contenedores de otro ambiente | Añadir replica a stop/rm; eliminar referencias ajenas |

---

## Mejoras al Dockerfile / scripts de imagen (opcionales, fuera del scope del MVP)

- `ADD *.sh` → `COPY *.sh` (COPY es preferido para archivos locales)
- `install_tools.sh`: añadir `set -e`
- `install_php.sh`: añadir `--no-install-recommends`
- `deploy.sh`: añadir `set -e` al inicio

---

## Criterio de éxito del POC

Al ejecutar `log.sh` después de que el `api_app` haya procesado requests:
1. `principal_db` muestra queries de escritura **y** lectura del usuario `user`
2. `api_db` muestra **únicamente** queries SELECT del usuario `readonly`
3. En `api_db` **no aparecen** INSERT, UPDATE ni DELETE

---

## Archivos fuera de scope

- `images/` — el Dockerfile y scripts de imagen se mantienen sin cambios para este MVP
- `mantenimiento.sh` — sin cambios
