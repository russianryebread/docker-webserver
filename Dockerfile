FROM nginx:1.17.5-alpine

# MAINTAINER OF THE PACKAGE.
LABEL maintainer="Ryan Hoshor <ryan@hoshor.me>"

# trust this project public key to trust the packages.
ADD https://dl.bintray.com/php-alpine/key/php-alpine.rsa.pub /etc/apk/keys/php-alpine.rsa.pub

# CONFIGURE ALPINE REPOSITORIES AND PHP BUILD DIR.
ARG PHP_VERSION=7.4
ARG ALPINE_VERSION=3.9
ARG NODE_VERSION=12.

# INSTALL SOME SYSTEM PACKAGES.
RUN apk --update --no-cache add \
        ca-certificates \
        bash \
        supervisor \
        nodejs \
        npm \
    #
    && echo "http://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/main" > /etc/apk/repositories \
    && echo "http://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/community" >> /etc/apk/repositories \
    && echo "https://dl.bintray.com/php-alpine/v${ALPINE_VERSION}/php-${PHP_VERSION}" >> /etc/apk/repositories \
    # 
    # INSTALL PHP AND SOME EXTENSIONS. SEE: https://github.com/codecasts/php-alpine
    && apk add --no-cache --update \
        php-fpm \
        php \
        php-ctype \
        php-curl \
        php-dom \
        php-json \
        php-mbstring \
        php-openssl \
        php-pdo \
        php-pdo_mysql \
        php-phar \
        php-redis \
        php-session \
        php-xml \
        php-zlib \
    && ln -s /usr/bin/php7 /usr/bin/php \
    # 
    # CONFIGURE WEB SERVER.
    && mkdir -p /var/www \
    && mkdir -p /run/php \
    && mkdir -p /run/nginx \
    && mkdir -p /var/log/supervisor \
    && mkdir -p /etc/nginx/sites-enabled \
    && mkdir -p /etc/nginx/sites-available \
    && rm /etc/nginx/nginx.conf \
    && rm /etc/php7/php-fpm.d/www.conf \
    && rm /etc/php7/php.ini

# INSTALL COMPOSER.
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php -r "if (hash_file('SHA384', 'composer-setup.php') === file_get_contents('https://composer.github.io/installer.sig')) { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
    && php composer-setup.php --install-dir=/usr/bin --filename=composer \
    && php -r "unlink('composer-setup.php');"

# ADD START SCRIPT, SUPERVISOR CONFIG, NGINX CONFIG AND RUN SCRIPTS.
ADD start.sh /start.sh
ADD config/supervisor/supervisord.conf /etc/supervisord.conf
ADD config/nginx/nginx.conf /etc/nginx/nginx.conf
ADD config/nginx/site.conf /etc/nginx/sites-available/default.conf
ADD config/php/php.ini /etc/php7/php.ini
ADD config/php-fpm/www.conf /etc/php7/php-fpm.d/www.conf
RUN chmod 755 /start.sh

# EXPOSE PORTS!
ARG NGINX_HTTP_PORT=80
ARG NGINX_HTTPS_PORT=443
EXPOSE ${NGINX_HTTPS_PORT} ${NGINX_HTTP_PORT}

# SET THE WORK DIRECTORY.
WORKDIR /var/www

# KICKSTART!
CMD ["/start.sh"]
