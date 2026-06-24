FROM ubuntu:24.04

ARG moodle_version
ARG moodle_tag
ARG php_version

ARG DEBIAN_FRONTEND=noninteractive

# 1. Área de trabajo temporal para los scripts de construcción
WORKDIR /tmp/scripts/

# Copiar todos los scripts
ADD *.sh ./
RUN sed -i 's/\r$//' ./*.sh && chmod +x ./*.sh

# 2. Ejecutar instalaciones
RUN ./install_tools.sh
RUN ./install_php.sh ${php_version}
RUN ./install_apache.sh

# 3. Descargar Moodle en su ruta definitiva
WORKDIR /var/www/
RUN /tmp/scripts/download_moodle.sh file ${moodle_version} ${moodle_tag}
ADD info.php ./html/info.php

# Crear directorio de datos
RUN mkdir -p /var/www/moodledata

# 4. Mover los scripts de tiempo de ejecución a una ruta segura del sistema
RUN mv /tmp/scripts/install_moodle.sh /usr/local/bin/install_moodle.sh
RUN mv /tmp/scripts/set_permissions.sh /usr/local/bin/set_permissions.sh

# 5. Aplicar permisos seguros iniciales
RUN /usr/local/bin/set_permissions.sh

# 6. Eliminar todos los scripts temporales de construcción para no dejar rastro
RUN rm -rf /tmp/scripts/

EXPOSE 80
CMD ["apachectl", "-D", "FOREGROUND"]