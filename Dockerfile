FROM php:8.2-apache

# Install system dependencies and PHP extensions required by Chamilo
RUN apt-get update && apt-get install -y \
    libicu-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    libxml2-dev \
    libcurl4-openssl-dev \
    libonig-dev \
    libldap2-dev \
    zlib1g-dev \
    libxapian-dev \
    pkg-config \
    unzip \
    git \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ || docker-php-ext-configure ldap \
    && docker-php-ext-install -j$(nproc) \
        intl \
        pdo \
        pdo_mysql \
        mysqli \
        zip \
        gd \
        curl \
        mbstring \
        xml \
        soap \
        ldap \
    && pecl install apcu \
    && docker-php-ext-enable apcu \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Note: Xapian PHP extension typically requires manual compilation
# The libxapian-dev package is installed above for system-level support
# To enable Xapian PHP extension, you may need to compile it separately

# Enable Apache mod_rewrite and other required modules
RUN a2enmod rewrite headers expires

# Configure Apache
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Copy Apache virtual host configuration
COPY 000-default.conf /etc/apache2/sites-available/000-default.conf
RUN a2ensite 000-default.conf

# Configure PHP settings for Chamilo
RUN echo "display_errors = Off" >> /usr/local/etc/php/conf.d/chamilo.ini \
    && echo "short_open_tag = Off" >> /usr/local/etc/php/conf.d/chamilo.ini \
    && echo "session.cookie_httponly = On" >> /usr/local/etc/php/conf.d/chamilo.ini \
    && echo "upload_max_filesize = 100M" >> /usr/local/etc/php/conf.d/chamilo.ini \
    && echo "post_max_size = 100M" >> /usr/local/etc/php/conf.d/chamilo.ini \
    && echo "memory_limit = 512M" >> /usr/local/etc/php/conf.d/chamilo.ini \
    && echo "error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT" >> /usr/local/etc/php/conf.d/chamilo.ini

# Set working directory
WORKDIR /var/www/html

# Create entrypoint script to set permissions
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Expose port 80
EXPOSE 80

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
