FROM ubuntu:24.04

ARG moodle_version
ARG moodle_tag
ARG php_version

ARG DEBIAN_FRONTEND=noninteractive

WORKDIR /var/www/

ADD install_tools.sh .
ADD install_php.sh .
ADD install_apache.sh .
ADD download_moodle.sh .
ADD set_permissions.sh .
ADD install_moodle.sh .

RUN chmod +x ./*.sh

RUN ./install_tools.sh
RUN ./install_php.sh ${php_version}
RUN ./install_apache.sh
RUN ./download_moodle.sh file ${moodle_version} ${moodle_tag}

ADD info.php ./html/info.php
RUN mkdir -p /var/www/moodledata

RUN ./set_permissions.sh

EXPOSE 80
CMD ["apachectl", "-D", "FOREGROUND"]