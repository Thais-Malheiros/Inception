# DEV_DOC

## 1. Purpose and scope

This document is intended for developers who want to understand, configure and maintain the Inception stack that runs WordPress on top of MariaDB and Nginx using Docker and a Makefile‑driven workflow.  
It covers prerequisites, environment setup, build and run steps using the Makefile, management commands and how data is stored and persists across container recreations.

## 2. Environment setup from scratch

### 2.1 Prerequisites

- Docker and Docker Compose installed on the host.  
- A Unix‑like host where `/home/${LOGIN}` exists; `LOGIN` is defined at the top of the Makefile (default `LOGIN = cadete`) and must match your 42 login.  
- TLS certificate and key files for Nginx (`nginx.crt`, `nginx.key`) placed or mounted where `nginx.conf` expects them (`/etc/nginx/ssl`).

### 2.2 Configuration files and secrets

1. **Makefile**  
   - `LOGIN`: used to set `VOLUMES_PATH = /home/$(LOGIN)/data` and to manage the host entry `${LOGIN}.42.fr`.  
   - `VOLUMES_PATH`: base path for bind‑mounted volumes (`${VOLUMES_PATH}/mariadb` and `${VOLUMES_PATH}/wordpress`).  
   - `DOCKER_COMPOSE_FILE = ./srcs/docker-compose.yml` and `DOCKER_COMPOSE_COMMAND = docker compose -f ${DOCKER_COMPOSE_FILE}` define the Compose file location used by all targets.

2. **`.env` file (project root)**  
   Contains all environment variables consumed by Docker Compose and the initialization scripts:

   - Database: `DBNAME`, `DBUSER`, `DBPASS`.  
   - WordPress: `DOMAIN`, `DBHOST`, `WPADM`, `WPADMPASS`, `WPADMMAIL`, `WPUSER`, `WPUSERPASS`, `WPUSERMAIL`.

   This file must not be committed in real projects and should be protected by proper filesystem permissions.

3. **Nginx configuration**  
   `nginx.conf` defines:

   - HTTPS virtual host on port 443.  
   - `server_name` (for example `${LOGIN}.42.fr`).  
   - SSL certificate paths under `/etc/nginx/ssl`.  
   - Root directory `/var/www/html` and FastCGI forwarding of PHP to `wordpress:9000`.

4. **Entry scripts**  
   - `db-entry.sh`: executed at build time in the MariaDB Dockerfile, creating the database, user and grants via `mariadb -u root -e ...` commands.  
   - `wp-entry.sh`: executed at container startup, running WP‑CLI commands to configure and install WordPress if `wp-config.php` is missing, then starting `php-fpm8.1 -F`.

### 2.3 Data directories

Data is persisted through bind‑mounted volumes defined in `docker-compose.yml` and created by the `setup` target:

- `${VOLUMES_PATH}/mariadb` ( `/home/${LOGIN}/data/mariadb` ) → mounted into `/var/lib/mysql` in the MariaDB container.  
- `${VOLUMES_PATH}/wordpress` ( `/home/${LOGIN}/data/wordpress` ) → mounted into `/var/www/html` in the WordPress and Nginx containers.

The `setup` rule creates these directories with `mkdir -p` and sets permissions with `chmod 777` to avoid permission issues during development.

## 3. Building and launching with Makefile and Docker Compose

### 3.1 Docker Compose configuration

`srcs/docker-compose.yml` defines three services and their relationships:

- **mariadb**  
  - `build.context: requirements/mariadb`.  
  - `args`: `DBNAME`, `DBUSER`, `DBPASS`.  
  - `env_file: .env`.  
  - `volumes`: `mariadb:/var/lib/mysql`.  
  - `expose: 3306`.  
  - `networks: inception`.  
  - `restart: unless-stopped`.

- **wordpress**  
  - `build.context: requirements/wordpress`.  
  - `args`: `DOMAIN`, `DBHOST`, `WPUSER`, `WPUSERPASS`, `WPUSERMAIL`, `WPADM`, `WPADMPASS`, `WPADMMAIL`.  
  - `env_file: .env`.  
  - `volumes`: `wordpress:/var/www/html`.  
  - `depends_on: mariadb`.  
  - `expose: 9000`.  
  - `networks: inception`.  
  - `restart: unless-stopped`.

- **nginx**  
  - `build.context: requirements/nginx`.  
  - `volumes`: `wordpress:/var/www/html`.  
  - `depends_on: wordpress`.  
  - `ports: 443:443`.  
  - `networks: inception`.  
  - `restart: unless-stopped`.

Volumes `mariadb` and `wordpress` are defined as named volumes with `driver_opts` configured to bind `/home/${LOGIN}/data/mariadb` and `/home/${LOGIN}/data/wordpress`.  
Network `inceptionnetwork` is declared as a bridge network used by all services.

### 3.2 Makefile workflow

Key targets:

- `all`: default target that runs `setup` and then `up`.  
- `host`: ensures `/etc/hosts` contains `127.0.0.1  ${LOGIN}.42.fr` using `sed`, so the domain resolves locally.  
- `setup`: depends on `host`; creates `${VOLUMES_PATH}/mariadb` and `${VOLUMES_PATH}/wordpress` and sets `chmod 777` on both directories.  
- `build`: runs `docker compose -f ./srcs/docker-compose.yml build` to build all images.  
- `up`: depends on `build`; runs `docker compose -f ./srcs/docker-compose.yml up -d` to start the stack in detached mode.  
- `ps`: runs `docker compose -f ./srcs/docker-compose.yml ps` to show service status.  
- `ls`: runs `docker volume ls` to show volumes on the host.  
- `open-wp`: opens `http://$(LOGIN).42.fr` in Firefox as a convenience.  
- `clean`: depends on `host-clean`; runs `docker compose -f ./srcs/docker-compose.yml down --rmi all --volumes` to remove containers, images and volumes of this stack.  
- `reset`: stops and removes all containers, images, volumes and networks on the host, regardless of project.  
- `fclean`: prunes Docker system resources and removes some local directories/logs.

Note: there is a `downn` target that calls `docker compose ... downn`; this looks like a typo and is not used in the typical workflow.

### 3.3 Typical development cycle

1. Edit `LOGIN` in the Makefile and fill in `.env`.  
2. Run `make all` to set up directories, update `/etc/hosts`, build images and start containers.  
3. Use `make ps` and `docker compose -f ./srcs/docker-compose.yml logs <service>` to debug issues.  
4. When changing Dockerfiles or configuration, run `make build` followed by `make up` to rebuild and restart the stack.  
5. Use `make clean` for a project‑scoped cleanup or `make reset`/`make fclean` for a global Docker reset.

## 4. Managing containers and volumes

### 4.1 Container management

- List services and status:

make ps

Internally runs `docker compose -f ./srcs/docker-compose.yml ps`.

- View logs with Docker:

docker compose -f ./srcs/docker-compose.yml logs mariadb
docker compose -f ./srcs/docker-compose.yml logs wordpress
docker compose -f ./srcs/docker-compose.yml logs nginx

- Enter a container shell (for debugging):

docker exec -it mariadb /bin/bash
docker exec -it wordpress /bin/bash
docker exec -it nginx /bin/bash

### 4.2 Volumes and data

- List all volumes:

make ls

This runs `docker volume ls` and shows the `mariadb` and `wordpress` volumes among others.

- Inspect a specific volume manually:

docker volume inspect mariadb
docker volume inspect wordpress

Volumes are configured as bind mounts with:

- `mariadb` → `/home/${LOGIN}/data/mariadb` ↔ `/var/lib/mysql`.  
- `wordpress` → `/home/${LOGIN}/data/wordpress` ↔ `/var/www/html`.

Removing these volumes or deleting the corresponding host directories will permanently erase the database and WordPress data.

## 5. Data storage and persistence

MariaDB stores all database tables under `/var/lib/mysql` inside the container, mapped to `/home/${LOGIN}/data/mariadb` on the host through the bind‑mounted `mariadb` volume.  
WordPress stores its core files, themes, plugins and uploads under `/var/www/html`, mapped to `/home/${LOGIN}/data/wordpress` on the host via the `wordpress` volume, which is also shared with Nginx.

Because data lives in these host directories, containers can be rebuilt or replaced without losing persistent state, as long as the volumes are not removed and the directories under `/home/${LOGIN}/data` remain intact.  
A full reset of the project requires both removing volumes through `make clean` or `docker compose ... down -v` and deleting the corresponding host directories if a completely fresh start is needed.
