*This project has been created as part of the 42 curriculum by tmalheir.

# Inception

## Description

This project sets up a small, production‑like infrastructure using Docker to run a WordPress website backed by a MariaDB database and served over HTTPS by an Nginx reverse proxy.
The goal is to learn how to design, containerize and orchestrate multiple services, using Dockerfiles and Docker Compose instead of relying on pre‑built images.

The stack includes three main services: a MariaDB database, a PHP‑FPM container running WordPress, and an Nginx container acting as the HTTPS entry point for the website.
All persistent data is stored outside the containers using bind‑mounted volumes under the host home directory, allowing containers to be rebuilt without losing database contents or site files.

For end‑user information (how to access the site, credentials and basic checks), see `USER_DOC.md` at the repository root. 
For technical details (build, scripts, volumes, networking and data persistence), see `DEV_DOC.md`.

## Project description and design choices

### Use of Docker and sources

Each service (MariaDB, WordPress, Nginx) has its own custom Dockerfile written from a Debian base image, installing only the required packages and copying in configuration files and entrypoint scripts.

The `docker-compose.yml` file defines how these services are wired together: build contexts, environment variables, internal network, bind‑mounted volumes and exposed ports.

- MariaDB  
  - Built from `requirements/mariadb/Dockerfile`, which installs `mariadb-server`, prepares directories and runs an initialization script.
  - The `db-entry.sh` script is executed at build time to create the database, application user and grant permissions based on build arguments and environment variables.

- WordPress (PHP‑FPM)  
  - Built from `requirements/wordpress/Dockerfile`, which installs PHP‑FPM, WP‑CLI and the WordPress core.
  - The `wp-entry.sh` script runs on container start, generating `wp-config.php`, installing WordPress, creating the admin and an extra user, and finally starting `php-fpm8.1` in the foreground.

- Nginx  
  - Built from `requirements/nginx/Dockerfile` with a custom `nginx.conf` pointing the document root to `/var/www/html` and forwarding PHP requests to the `wordpress:9000` service.
  - TLS is enabled on port 443 using a certificate and key placed in `/etc/nginx/ssl` inside the container.

Environment variables and credentials are stored in a `.env` file at the root of the repository and injected into the containers through Docker Compose and build arguments.
Database data and WordPress files are persisted through bind‑mounted volumes under `/home/${HOSTLOGIN}/data/mariadb` and `/home/${HOSTLOGIN}/data/wordpress` on the host.

### Virtual Machines vs Docker

Virtual Machines run a full guest operating system on top of a hypervisor, with dedicated virtual hardware, making them heavier in terms of memory and disk usage, and slower to boot and duplicate.
Docker containers share the host kernel and isolate processes using namespaces and cgroups, resulting in smaller images, faster startup times and easier replication of environments from simple configuration files.

### Secrets vs Environment Variables

Environment variables are easy to configure and integrate with Docker Compose, but they are stored in plain text in files like `.env` and can be exposed in process lists or logs if not handled carefully.
Secrets management solutions (such as Docker secrets or external vaults) provide encrypted storage and controlled access to sensitive data, but add complexity and are often overkill for small, local projects like this one.

In this project, credentials are stored in a local `.env` file that is not meant to be committed, which is acceptable in a controlled development environment but not ideal for production.

### Docker Network vs Host Network

A Docker bridge network creates an isolated virtual network where containers can communicate by service name, hiding internal ports from the host and allowing per‑project network segregation.
Using the host network mode exposes services directly on the host networking stack, which can simplify certain setups but removes isolation and increases the risk of port conflicts and security issues.

This project uses a custom bridge network (`inception network`) so that `mariadb`, `wordpress` and `nginx` can communicate internally while only Nginx exposes port 443 on the host.

### Docker Volumes vs Bind Mounts

Docker named volumes are managed by Docker and store data in internal directories, offering portability and simple lifecycle management but hiding the exact location on the host by default.
Bind mounts map explicit directories from the host filesystem into containers, giving full control and visibility of data but depending on correct host paths and permissions.

Here, named volumes are configured with `driver_opts` of type `bind`, effectively using bind mounts to map `/home/${HOSTLOGIN}/data/mariadb` and `/home/${HOSTLOGIN}/data/wordpress` directly into `/var/lib/mysql` and `/var/www/html` in the containers.

## Instructions

### Prerequisites

- A Unix‑like system with Docker and Docker Compose installed.  
- A valid 42 login configured in the Makefile (variable `LOGIN`), used to build the host paths `/home/${LOGIN}/data`.
- TLS certificate and key available for Nginx (`nginx.crt` and `nginx.key`), mounted or copied to the path used in `nginx.conf`.

### Setup with the Makefile

1. Adjust the `LOGIN` variable in the Makefile to match your 42 login (for example `LOGIN = tmalheir`).
2. Create a `.env` file at the project root with at least:

   - **Database**: `DBNAME`, `DBUSER`, `DBPASS`.
   - **WordPress**: `DOMAIN`, `DBHOST`, `WPADM`, `WPADMPASS`, `WPADMMAIL`, `WPUSER`, `WPUSERPASS`, `WPUSERMAIL`.

3. Run:

make all

Target `all` runs `setup` and then `up`.  
- `setup` creates the directories `${VOLUMES_PATH}/mariadb` and `${VOLUMES_PATH}/wordpress` under `/home/${LOGIN}/data`, sets permissions and ensures `/etc/hosts` has an entry mapping `127.0.0.1  ${LOGIN}.42.fr`.
- `up` builds the images and starts the stack in detached mode using `docker compose -f ./srcs/docker-compose.yml up -d`.

### Running and stopping

Main Makefile targets:

- Start (build + up + host setup):

make all

- Build only:

make build

- Check running containers:

make ps

- List Docker volumes:

make ls

- Open WordPress in Firefox:

make open-wp

This opens `http://$(LOGIN).42.fr` in the local browser, using the `/etc/hosts` entry created by `make host`.

- Clean project containers, images and volumes for this stack:

make clean

This runs `docker compose down --rmi all --volumes` on `srcs/docker-compose.yml` and removes the host entry via `host-clean`.[file:3]

- Hard reset of all Docker resources on the host (use with care):

make reset
make fclean

`reset` stops and removes all containers, images, volumes and networks, while `fclean` prunes Docker system data and removes local directories/logs referenced in the Makefile.

After `make all`, the website is available at `https://$(LOGIN).42.fr` (or at the URL defined by `DOMAIN` if DNS/hosts are adjusted accordingly).

## Resources

### Documentation and articles

- Docker documentation: images, containers, networks and volumes (for understanding the Compose file and custom Dockerfiles).
- MariaDB documentation: installation, configuration, user management and SQL privileges (used to design `db-entry.sh`).
- WordPress and WP‑CLI documentation: installation, configuration and command‑line management (used to design `wp-entry.sh` and initial site setup).
- Nginx documentation: HTTPS configuration, FastCGI proxy and virtual hosts (used to prepare `nginx.conf`).

### AI usage

AI assistance was used to:

- Structure and write the three documentation files (`README.md`, `USER_DOC.md` and `DEV_DOC.md`), ensuring they match the Inception subject requirements and clearly separate user and developer concerns.
- Describe the architecture of the stack based on the existing `docker-compose.yml`, Dockerfiles and entrypoint scripts, including services, environment variables, volumes and networking choices.
- Draft the conceptual comparisons between Virtual Machines and Docker, secrets and environment variables, Docker network modes, and volumes versus bind mounts, aligning them with practices used in this project.