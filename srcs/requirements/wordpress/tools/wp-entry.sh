#!/bin/bash

# If the WordPress configuration file exists, proceed with setup
# This prevents reconfiguring WordPress every time the container restarts
if [ ! -f /var/www/html/wp-config.php ]; then

    # Generate wp-config.php using environment variables
    # Sets database name, user, password, host and table prefix
    wp --allow-root config create \
        --dbname=$DB_NAME \
        --dbuser=$WP_USER \
        --dbpass=$WP_USER_PASS \
        --dbhost=$DB_HOST \
        --dbprefix="wp_"
    
    # Install WordPress core with the given site title, URL and admin credentials
    wp core install --allow-root \
        --path=/var/www/html \
        --title="inception" \
        --url=$DOMAIN \
        --admin_user=$WP_ADM \
        --admin_password=$WP_ADM_PASS \
        --admin_email=$WP_ADM_MAIL
    
    # Create an additional WordPress user with author role
    wp user create --allow-root \
        --path=/var/www/html \
        $WP_USER \
        $WP_USER_MAIL \
        --user_pass=$WP_USER_PASS \
        --role='author'
    
    # Activate the Twenty Twenty-Four WordPress theme
    wp --allow-root theme activate twentytwentyfour

fi

# Run PHP-FPM 8.1 in the foreground so the container stays alive
exec php-fpm8.1 -F