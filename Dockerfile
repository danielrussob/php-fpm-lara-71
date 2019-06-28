FROM dnafactory/php-fpm-71

RUN echo "deb http://archive.debian.org/debian jessie-backports main" > /etc/apt/sources.list.d/jessie-backports.list
RUN sed -i '/deb http:\/\/deb.debian.org\/debian jessie-updates main/d' /etc/apt/sources.list
RUN set -eux; \
        # Jessie's apt doesn't support [check-valid-until=no] so we have to use this instead
        apt-get -o Acquire::Check-Valid-Until=false update;

RUN apt-get -o Acquire::Check-Valid-Until=false update -yqq && \
    apt-get -y install libxml2-dev php-soap && \
    docker-php-ext-install soap \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get purge -y --auto-remove

RUN pecl install xdebug && \
    docker-php-ext-enable xdebug
COPY ./xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

RUN docker-php-ext-install zip
RUN docker-php-ext-install bcmath
RUN docker-php-ext-install exif
RUN docker-php-ext-install mysqli
RUN docker-php-ext-install pcntl

RUN apt-get -o Acquire::Check-Valid-Until=false update -yqq && \
    apt-get install -y zlib1g-dev libicu-dev g++ && \
    docker-php-ext-configure intl && \
    docker-php-ext-install intl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get purge -y --auto-remove

USER root
RUN apt-get -o Acquire::Check-Valid-Until=false update -yqq && \
        apt-get install -y --force-yes jpegoptim optipng pngquant gifsicle \
        && rm -rf /var/lib/apt/lists/* \
        && apt-get purge -y --auto-remove

RUN apt-get -o Acquire::Check-Valid-Until=false update -y && \
    apt-get install -y libmagickwand-dev imagemagick cron supervisor && \
    pecl install imagick && \
    docker-php-ext-enable imagick \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get purge -y --auto-remove

#
#--------------------------------------------------------------------------
# Final Touch
#--------------------------------------------------------------------------
#

RUN apt-get -o Acquire::Check-Valid-Until=false update && apt-get install -y \
    mysql-client \
    vim \
    telnet \
    netcat \
    git-core \
    nano \
    zip \
	openssh-client \
	openssh-server \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get purge -y --auto-remove

RUN curl -s http://getcomposer.org/installer | php && \
    echo "export PATH=${PATH}:/var/www/vendor/bin" >> ~/.bashrc && \
    mv composer.phar /usr/local/bin/composer

RUN sed  -ibak -re "s/PermitRootLogin without-password/PermitRootLogin yes/g" /etc/ssh/sshd_config
RUN echo "root:root" | chpasswd

RUN systemctl enable ssh

RUN mkdir /var/www/sites-available
RUN mkdir /var/www/logs
RUN mkdir /var/www/dumps

RUN usermod -u 1000 www-data

COPY laravel.conf /var/www/sites-available/laravel.conf
RUN rm /var/www/sites-available/default.conf -Rf
RUN mkdir /var/www/laravel
RUN chown -R www-data:www-data /var/www/laravel

WORKDIR /var/www
#CMD ["php-fpm"]
CMD service ssh restart && php-fpm

EXPOSE 9000