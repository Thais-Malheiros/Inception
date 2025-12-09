#!/bin/bash

set -e

service mariadb start

# Create the database if it does not already exist
mariadb -u root -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"

# Create the application user with the provided credentials, allowing access from any host
mariadb -u root -e "CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_PASS';"

# Grant full privileges on the specified database to the created user
mariadb -u root -e "GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'%';"

# Applies all privilege changes to ensure newly created users and permissions take effect immediately
mariadb -u root -e "FLUSH PRIVILEGES;"

service mariadb stop