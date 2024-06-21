# Base stage
FROM debian:12-slim AS base

LABEL version="1.0"
LABEL description="Imagen Apache sobre Bookworn"
LABEL vendor="Jhoncy Tech"

ENV APACHE_VERSION=${APACHE_VERSION:-2.4}
ENV PHP_VERSION=${PHP_VERSION:-8.1}

RUN apt-get -y update && apt-get -y install apt-transport-https ca-certificates lsb-release gnupg wget && \
    echo "deb http://deb.debian.org/debian $(lsb_release -sc) main contrib non-free" > /etc/apt/sources.list.d/backports.list && \
    apt-get -y update

COPY files-config/000-default.conf files-config/apache2.conf files-config/start.sh /root/

#---------------------------------------------------------------------------

# APACHE Stage
FROM base AS apache

RUN apt-get -y install apache2=${APACHE_VERSION}*

COPY --from=base /root/apache2.conf /etc/apache2/
COPY --from=base /root/000-default.conf /etc/apache2/sites-available/

#---------------------------------------------------------------------------

# PHP Stage
FROM apache AS php

# Añadir el repositorio de Sury para PHP
RUN wget https://packages.sury.org/php/apt.gpg -O /tmp/apt.gpg && apt-key add /tmp/apt.gpg && \
    echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list && \
    apt-get -y update

RUN apt-get -y update && apt-get -y install \
    php${PHP_VERSION} \
    php${PHP_VERSION}-xmlrpc \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-gd \
    php${PHP_VERSION}-cli \
    php${PHP_VERSION}-mysql \
    php${PHP_VERSION}-zip \
    php${PHP_VERSION}-common

#---------------------------------------------------------------------------

# FINAL Stage
FROM php AS final

WORKDIR /var/www/html

COPY --from=base /root/start.sh /usr/local/bin/start.sh

RUN apt-get -y install mariadb-client dos2unix && \
    dos2unix /usr/local/bin/start.sh

CMD ["/usr/local/bin/start.sh"]