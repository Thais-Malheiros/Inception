# USER_DOC

## 1. Overview of the services

This project runs a WordPress website using three containers managed by Docker Compose, orchestrated through the Makefile.
The stack includes a MariaDB database, a PHP‑FPM container running WordPress and an Nginx server that exposes the site over HTTPS on port 443.

- **MariaDB**: stores all WordPress data (posts, users, configuration) and listens on port 3306 inside the Docker network only.
- **WordPress (PHP‑FPM)**: executes the PHP code of the site and receives requests from Nginx on port 9000 inside the Docker network.
- **Nginx**: serves the website from `/var/www/html` and forwards PHP requests to the WordPress container, publishing port 443 on the host.

The host name `${LOGIN}.42.fr` is mapped to `127.0.0.1` in `/etc/hosts` by the Makefile, so you can access the site using that address in your browser.

## 2. Starting and stopping the project

All commands below must be run from the repository root.

### Start the project (recommended)

make all

This will:

- Configure `/etc/hosts` to add `127.0.0.1  ${LOGIN}.42.fr` if needed (`make host`).
- Create data directories `/home/${LOGIN}/data/mariadb` and `/home/${LOGIN}/data/wordpress` with correct permissions (`make setup`).
- Build Docker images and start the containers in detached mode using `srcs/docker-compose.yml` (`make up`).

### Stop and clean the project

- To remove containers, images and volumes for this stack only:

make clean

This runs `docker compose -f ./srcs/docker-compose.yml down --rmi all --volumes` and removes the host entry via `host-clean`.[file:3][file:7]

- To perform a global reset of Docker resources on your machine (use with extreme care):

make reset
make fclean

`reset` stops and removes all containers, images, volumes and networks, and `fclean` prunes Docker system data and deletes some local directories/logs defined in the Makefile.[file:7]

## 3. Accessing the website and admin panel

After running `make all`:

- **Website**:  
Open one of the following in your browser:
- `https://$(LOGIN).42.fr` (using the `/etc/hosts` entry created by `make host`).[file:5][file:7]  
- Or `https://<DOMAIN>` if your `.env` defines another domain and you have proper DNS/hosts configuration.

- **WordPress administration panel**:  
Open `https://<DOMAIN>/wp-admin` (or `https://$(LOGIN).42.fr/wp-admin` if that matches your `DOMAIN`) and log in with the administrator credentials defined in the `.env` file (`WPADM` / `WPADMPASS`).

You can also run:

make open-wp

to automatically open `http://$(LOGIN).42.fr` in Firefox; this is mainly a convenience for accessing the site locally.

## 4. Locating and managing credentials

All credentials and configuration values are stored in a `.env` file at the root of the project.
This file is loaded by Docker Compose and used by the database initialization script and the WordPress setup script.

Main variables:

- **Database (MariaDB)**  
  - `DBNAME`: name of the WordPress database.  
  - `DBUSER`: database user used by WordPress.  
  - `DBPASS`: password for the database user.

- **WordPress**  
  - `DOMAIN`: public URL of the site (for example `${LOGIN}.42.fr`).
  - `DBHOST`: database host, usually `mariadb:3306` inside the Docker network.
  - `WPADM`, `WPADMPASS`, `WPADMMAIL`: WordPress admin login, password and email used during initial installation.
  - `WPUSER`, `WPUSERPASS`, `WPUSERMAIL`: additional WordPress user with author role.

To change passwords or users after installation, it is usually easier to use the WordPress admin panel; editing `.env` affects future installs or full resets.

## 5. Checking that services are running correctly

### Using Makefile helpers

- Show the status of the containers:

make ps

This runs `docker compose -f ./srcs/docker-compose.yml ps` and should list `mariadb`, `wordpress` and `nginx` as running.[file:3][file:7]

- List Docker volumes on the system:

make ls

### Using Docker commands directly

From the project root:

- Check logs for one service:

docker compose -f ./srcs/docker-compose.yml logs mariadb
docker compose -f ./srcs/docker-compose.yml logs wordpress
docker compose -f ./srcs/docker-compose.yml logs nginx

Use these to spot issues with database initialization, WordPress setup or Nginx configuration.

- Functional check with the browser:  
- Open the site URL and verify the homepage loads.  
- Open `/wp-admin` and ensure you can log in as the admin user.

If something is wrong, verify the `.env` content, confirm that `LOGIN` in the Makefile and the `DOMAIN` value are consistent, and re‑run `make all` after fixing configuration.
