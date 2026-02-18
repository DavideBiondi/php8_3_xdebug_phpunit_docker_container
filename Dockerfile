FROM php:8.3-fpm

RUN apt-get update && apt-get install -y \
    git \
    curl \
    zip \
    unzip \
    sqlite3 \
    libzip-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libonig-dev \
    libxml2-dev \
    libcurl4-openssl-dev
   && docker-php-ext-configure gd --with-freetype --with-jpeg \
   && docker-php-ext-install \
        pdo \
        pdo_sqlite \
        pdo_mysql \
        mysqli \
        mbstring \
        exif \
        pcntl \
        bcmath \
        gd \
zip \
opcache

# Installa apcu
RUN pecl install apcu && docker-php-ext-enable apcu

# Installa pcov
RUN pecl install pcov && docker-php-ext-enable pcov

# Installa Xdebug per debug
RUN pecl install xdebug \
    && docker-php-ext-enable xdebug

# Installa Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Installa PHPUnit globalmente
RUN composer global require phpunit/phpunit --prefer-dist --no-progress --no-interaction

#Allineamento UID utente e www-data
RUN usermod -u 1000 www-data
RUN groupmod -g 1000 www-data

# Aggiungi composer global bin al PATH
ENV PATH="/root/.composer/vendor/bin:${PATH}"

# Imposta la cartella di lavoro
WORKDIR /var/www/html

# Espone la porta PHP-FPM
EXPOSE 9000

CMD ["php-fpm"]
