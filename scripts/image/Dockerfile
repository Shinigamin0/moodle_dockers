ARG moodle_tag="MOODLE_404_STABLE"
ARG moodle_version="404"
ARG php_version="8.1"

FROM ubuntu:22.04
ARG DEBIAN_FRONTEND=noninteractive

WORKDIR /var/www/

ADD install_tools.sh .
ADD install_php.sh .
ADD install_apache.sh .
ADD install_permissions.sh .
ADD download_moodle.sh .

RUN chmod +x ./install_*
RUN chmod +x ./download_moodle.sh

RUN ./install_tools.sh
RUN ./install_php.sh ${php_version}
RUN ./install_apache.sh
RUN ./download_moodle.sh file ${moodle_version} ${moodle_tag}

ADD info.php ./html/info.php
RUN chmod +x ./html/info.php

RUN chown -R www-data. ./html/

EXPOSE 80
CMD apachectl -D FOREGROUND
