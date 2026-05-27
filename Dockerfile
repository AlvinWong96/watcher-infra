FROM php:8.2-apache

# Install system dependencies and PHP extensions
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libcurl4-openssl-dev \
        libxml2-dev \
    && docker-php-ext-install curl \
    && a2enmod rewrite \
    && rm -rf /var/lib/apt/lists/*

# simplexml is bundled with PHP — just ensure it's enabled
RUN docker-php-ext-enable simplexml 2>/dev/null || true

# Set recommended PHP settings
RUN echo "expose_php = Off" >> /usr/local/etc/php/php.ini \
    && echo "display_errors = On" >> /usr/local/etc/php/php.ini \
    && echo "log_errors = On" >> /usr/local/etc/php/php.ini

# Allow .htaccess overrides
RUN sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf

WORKDIR /var/www/html

EXPOSE 80
