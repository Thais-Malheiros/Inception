# Base image
FROM debian:oldstable

# Update package lists and upgrade installed packages
RUN apt-get update && apt-get upgrade -y

# Install Nginx web server and OpenSSL, clean apt cache to reduce image size
RUN apt-get install nginx openssl -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create directory to store SSL certificates
RUN mkdir -p /etc/nginx/ssl

# Generate self-signed SSL certificate for HTTPS
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/nginx.key \
    - -out /etc/nginx/ssl/nginx.crt \
    -subj "/C=BR/ST=Sao Paulo/L=Sao Paulo/O=42/CN=tmalheir.42.fr"

# Copy custom Nginx configuration
COPY conf/nginx.conf /etc/nginx/conf.d

# Adjust permissions of the /var/www directory
RUN chmod 755 /var/www 

# Change ownership of /var/www to www-data user and group
RUN chown -R www-data:www-data /var/www

# Set the default command for the container
CMD ["nginx", "-g", "daemon off;"]