# Base image
FROM        debian:oldstable

# Define build arguments passed from docker-compose
ARG         DB_NAME
ARG         DB_USER
ARG         DB_PASS

# Update package lists and upgrade installed packages
RUN         apt-get update && apt-get upgrade -y

# Install MariaDB server and remove cached package files to reduce image size
RUN         apt-get install -y mariadb-server && apt-get clean

# Create necessary directories for MariaDB runtime and data storage
RUN         mkdir -p /var/lib/mysql /var/run/mysqld

# Set correct ownership so MariaDB can read/write without permission issues
RUN         chown -R mysql:mysql /var/lib/mysql /var/run/mysqld

# Ensure the mysqld runtime directory is accessible during container startup
RUN         chmod 777 /var/run/mysqld

# Copy custom MariaDB configuration file into the container
COPY        ./conf/my.cnf /etc/mysql/my.cnf

# Copy and prepare the database initialization script
COPY        ./tools/db-entry.sh /tmp/db-entry.sh

RUN         chmod 777 /tmp/db-entry.sh && bash /tmp/db-entry.sh

# Start MariaDB using a safe wrapper that handles signals and restarts
ENTRYPOINT [ "mysqld_safe" ]