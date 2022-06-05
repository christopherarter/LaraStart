FROM php:8.1-alpine3.15

RUN docker-php-ext-install mysqli pdo pdo_mysql && docker-php-ext-enable pdo_mysql
RUN apk --no-cache add \
  php8-tokenizer \
  php8-session \
  php8-fpm \
  php8-json \
  php8-mbstring \
  php8-pdo_mysql \
  php8-xmlreader \
  php8-zlib \
  supervisor
  

# Configure supervisord
COPY docker/php/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Configure PHP-FPM
COPY docker/php/fpm-pool.conf /etc/php8/php-fpm.d/www.conf
COPY docker/php/php.ini /etc/php8/conf.d/custom.ini

RUN mkdir -p /var/www/html/storage

# Add application
COPY . /var/www/html/

# Allow php-fpm user to write to logs
RUN chown -R www-data:www-data /var/www/html/storage
RUN chmod -R 755 /var/www/html/storage

WORKDIR /var/www/html/

# composer install
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer
RUN composer install --no-ansi --no-interaction --no-plugins --no-progress --no-scripts --optimize-autoloader


RUN php artisan optimize:clear

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
EXPOSE 9000