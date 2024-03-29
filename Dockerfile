FROM ubuntu:16.04

LABEL maintainer="y.sogabe <y.sogabe@gmail.com>" \
      description="PHP7.3 include ImageMagick"

ENV LC_ALL C.UTF-8
ARG USER_NAME="laravel"
ARG ROOT_PASS="passwd!"

WORKDIR /tmp
# Install PHP7.3 ImageMgick
RUN set -x \
 && apt update \
 && apt upgrade -y \
 && apt install -y \
    software-properties-common \
 && add-apt-repository -y ppa:ondrej/php \
 && apt update \
 && apt install -y \
    php7.3 \
    php7.3-fpm \
    php7.3-mysql \
    php7.3-mbstring \
    php7.3-zip \
    php7.3-xml \
    php7.3-dev \
    php7.3-curl \
    php7.3-bz2 \
    php7.3-pgsql \
    unzip \
    imagemagick \
    libmagickwand-dev \
    pkg-config \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*
RUN pecl install imagick

# ImageMgick INI
RUN echo "; configuration for php imageMagick module" > /etc/php/7.3/mods-available/imagemagick.ini \
 && echo "; priority=20" >> /etc/php/7.3/mods-available/imagemagick.ini \
 && echo "extension=imagick.so" >> /etc/php/7.3/mods-available/imagemagick.ini \
 && ln -s /etc/php/7.3/mods-available/imagemagick.ini /etc/php/7.3/cli/conf.d/20-imagemagick.ini \
 && ln -s /etc/php/7.3/mods-available/imagemagick.ini /etc/php/7.3/fpm/conf.d/20-imagemagick.ini

# Install composer
RUN set -x \
 && php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
 && php -r "if (hash_file('sha384', 'composer-setup.php') === 'a5c698ffe4b8e849a443b120cd5ba38043260d5c4023dbf93e1558871f1f07f58274fc6f4c93bcfd858c6bd0775cd8d1') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
 && php composer-setup.php \
 && php -r "unlink('composer-setup.php');" \
 && mv composer.phar /usr/local/bin/composer

# working dir Setting
RUN set -x \
 && echo "root:${ROOT_PASS}" |chpasswd \
 && useradd --user-group --create-home --shell /bin/false ${USER_NAME} \
 && mkdir /app \
 && chown ${USER_NAME}:${USER_NAME} /app \
 && chmod 777 /app

COPY settings/www.conf /etc/php/7.3/fpm/pool.d/www.conf

# composer Setting
USER ${USER_NAME}
RUN set -x \
 && composer config -g repositories.packagist composer https://packagist.jp \
 && composer global require hirak/prestissimo

EXPOSE 9000
WORKDIR /app
VOLUME /app

STOPSIGNAL SIGTERM
CMD ["php-fpm"]