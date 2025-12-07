FROM php:8.3-fpm

# Aggiorna e installa dipendenze di sistema
RUN apt-get update && apt-get install -y \
    libzip-dev zip unzip \
    libpng-dev libjpeg-dev libfreetype6-dev \
    libxml2-dev libcurl4-openssl-dev \
    libonig-dev git curl \
    && docker-php-ext-install pdo pdo_mysql mysqli mbstring zip gd xml curl opcache \
    && docker-php-ext-configure gd --with-freetype --with-jpeg

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

# Aggiungi composer global bin al PATH
ENV PATH="/root/.composer/vendor/bin:${PATH}"

# Imposta la cartella di lavoro
WORKDIR /var/www/html

# Espone la porta PHP-FPM
EXPOSE 9000

CMD ["php-fpm"]
