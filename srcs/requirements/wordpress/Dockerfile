# Base image
FROM    debian:oldstable

ARG DOMAIN
ARG DB_HOST
ARG WP_USER
ARG WP_USER_PASS
ARG WP_USER_MAIL
ARG WP_ADM
ARG WP_ADM_PASS
ARG WP_ADM_MAIL

# Set working directory to the web root where WordPress will be installed
WORKDIR /var/www/html/

# Update package lists and upgrade installed packages
RUN apt-get update && apt-get upgrade -y

RUN apt-get install -y lsb-release apt-transport-https ca-certificates wget -y

RUN wget -qO /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg

RUN echo "deb https://packages.sury.org/php $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list

RUN apt-get update

# Install php-fpm, php-mysql, MariaDB client and wget and remove cached package files to reduce image size
RUN apt-get install php8.1 php8.1-fpm php8.1-mysql mariadb-client wordpress wget -y

RUN apt-get clean

# Create directory required for the PHP-FPM socket
RUN mkdir -p /run/php

# Set correct ownership and permissions for the web root directory
RUN chown -R www-data:www-data /var/www/html && chmod 755 /var/www/html

# Download WP-CLI binary into /usr/local/bin
RUN wget -O /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar

# Make WP-CLI executable and download the WordPress core into the working directory
RUN chmod 777 /usr/local/bin/wp && wp core download --allow-root --path=/var/www/html

# Copy custom PHP-FPM configuration file
COPY conf/www.conf /etc/php/8.1/fpm/pool.d/www.conf

# Copy WordPress entrypoint script
COPY tools/wp-entry.sh /tmp/wp-entry.sh

# Make entrypoint script executable
RUN chmod 777 /tmp/wp-entry.sh

# Run initialization script at container startup
ENTRYPOINT [ "/tmp/wp-entry.sh" ]