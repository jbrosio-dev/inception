# Developer Documentation

This document explains how to set up, build, run and maintain the Inception project from a developer's point of view.

## 1. Set up the environment from scratch

### Prerequisites

- A Linux virtual machine (the project must run inside a VM).
- Docker Engine and the Docker Compose plugin:
  ```bash
  docker --version
  docker compose version
  ```
- `make` and `git`.
- `sudo` access (for `/etc/hosts` and the data folders).

### Domain name

```bash
echo "127.0.0.1 jbrosio.42.fr" | sudo tee -a /etc/hosts
```

### Host data folders

The named volumes store their data under `/home/jbrosio/data`:

```bash
mkdir -p /home/jbrosio/data/mariadb /home/jbrosio/data/wordpress
```

(The Makefile may already create them; check it.)

### Configuration file: `srcs/.env`

Holds non-confidential variables. These are the ones used by the scripts in this repository:

```env
DOMAIN_NAME=jbrosio.42.fr

# MariaDB
SQL_DATABASE=<database_name>
SQL_USER=<database_user>

# WordPress
WP_ADMIN_USER=<admin_username>        # must NOT contain "admin" / "administrator"
WP_ADMIN_EMAIL=<admin_email>
WP_USER=<second_user_username>
WP_USER_EMAIL=<second_user_email>

# FTP
FTP_USER=<ftp_username>
```

### Secrets: `secrets/`

Confidential values are read by the scripts from `/run/secrets/<name>`. Create one file per secret in the `secrets/` folder (containing only the password) and declare them in `docker-compose.yml`:

| Secret name           | Used by                | Purpose                         |
|-----------------------|------------------------|---------------------------------|
| `sql_password`        | mariadb, wordpress     | Password of the WordPress DB user |
| `sql_root_password`   | mariadb                | MariaDB root password           |
| `wp_admin_password`   | wordpress              | WordPress administrator password |
| `wp_user_password`    | wordpress              | WordPress author password       |
| `ftp_password`        | ftp                    | FTP user password               |

> ⚠️ `secrets/` and `srcs/.env` **must be listed in `.gitignore`**. Any credential found in the Git repository results in project failure.

## 2. Build and launch the project

### Makefile targets

| Command        | Effect                                                              |
|----------------|---------------------------------------------------------------------|
| `make`         | Builds the images and starts all containers (`docker compose up -d --build`) |
| `make down`    | Stops the containers                                                |
| `make clean`   | Stops and removes containers and networks                           |
| `make fclean`  | `clean` + removes images, volumes and the host data                 |
| `make re`      | `fclean` followed by `make`                                         |

The Makefile calls Docker Compose with `srcs/docker-compose.yml`. Equivalent manual command:

```bash
docker compose -f srcs/docker-compose.yml up -d --build
```

### Project layout

```
srcs/requirements/
├── nginx/        # TLS 1.2/1.3 reverse proxy, port 443
├── wordpress/    # php-fpm 8.2 + WP-CLI, tools/wp_install.sh
├── mariadb/      # tools/init_db.sh
└── bonus/
    ├── redis/
    ├── ftp/          # vsftpd, tools/ftp_start.sh
    ├── adminer/
    ├── static_web/   # lighttpd, html/index.html
    └── portainer/
```

### What the init scripts do

- **`mariadb/tools/init_db.sh`**: if `/var/lib/mysql/$SQL_DATABASE` does not exist, starts MariaDB temporarily, creates the database and user, sets the root password, then shuts it down. Finally it runs `exec mysqld_safe` so MariaDB is PID 1.
- **`wordpress/tools/wp_install.sh`**: if `wp-config.php` is missing, downloads WordPress, waits for `mariadb:3306`, creates `wp-config.php`, installs the site, creates the administrator and an `author` user, configures and enables Redis, and fixes permissions. Finally it runs `exec php-fpm8.2 -F`.
- **`bonus/ftp/tools/ftp_start.sh`**: reads the FTP password from the secret, creates the FTP user (added to the `www-data` group) if needed, sets ownership of `/var/www/wordpress`, then runs `exec vsftpd /etc/vsftpd.conf`.

Because both installers check for existing data first, re-running `make` does not reinstall or overwrite anything in the volumes.

## 3. Manage containers and volumes

All commands use the compose file in `srcs/`:

```bash
alias dc='docker compose -f srcs/docker-compose.yml'
```

**Containers**

```bash
dc ps                        # status of the stack
dc logs -f <service>         # follow logs
dc exec <service> bash       # open a shell in a running container
dc restart <service>         # restart one service
dc up -d --build <service>   # rebuild and restart one service
dc down                      # stop and remove containers
```

**Images, network, volumes**

```bash
docker images
docker network ls
docker network inspect inception_net
docker volume ls
docker volume inspect <volume_name>
```

**Useful checks**

```bash
# Database
dc exec mariadb mysql -u root -p -e "SHOW DATABASES;"

# WordPress users (must be 2, admin name without "admin")
dc exec wordpress wp user list --allow-root --path=/var/www/wordpress

# Redis
dc exec redis redis-cli ping            # PONG
dc exec wordpress wp redis status --allow-root --path=/var/www/wordpress

# TLS
openssl s_client -connect jbrosio.42.fr:443 -tls1_2
openssl s_client -connect jbrosio.42.fr:443 -tls1_1   # must fail
```

## 4. Where data is stored and how it persists

| Data                  | Container path        | Docker named volume | Host path                      |
|-----------------------|-----------------------|---------------------|--------------------------------|
| WordPress database    | `/var/lib/mysql`      | MariaDB volume      | `/home/jbrosio/data/mariadb`   |
| WordPress site files  | `/var/www/wordpress`  | WordPress volume    | `/home/jbrosio/data/wordpress` |

- The WordPress volume is shared by the `wordpress`, `nginx` and `ftp` containers.
- Both volumes are Docker **named volumes** (bind mounts are not allowed for them) configured to store their data in `/home/jbrosio/data`.
- Data survives `make down`, `make clean` and container crashes/restarts. It is removed only by `make fclean` or by manually deleting the volumes and the host folders.
- Redis is a cache and does not need persistent data.
- Portainer mounts `/var/run/docker.sock` (a bind mount) to talk to the Docker daemon; this gives it wide control over Docker, so avoid exposing it outside a local environment.

## 5. Subject rules checklist

- [ ] Runs inside a virtual machine.
- [ ] `Makefile` at the root, builds everything through `docker-compose.yml`.
- [ ] One Dockerfile per service; image name = service name; base Debian Bookworm / Alpine (penultimate stable), no `latest` tag.
- [ ] No ready-made images pulled (only the Debian/Alpine base).
- [ ] NGINX is the only entrypoint of the mandatory part, port 443, TLS 1.2/1.3 only.
- [ ] WordPress + php-fpm without NGINX; MariaDB without NGINX.
- [ ] Two named volumes in `/home/jbrosio/data`; no bind mounts for them.
- [ ] `network` defined in `docker-compose.yml`; no `network: host`, `--link`, `links:`.
- [ ] Containers restart on crash; no `tail -f`, `sleep infinity`, `while true`, or `bash` as main process.
- [ ] Two WordPress users; administrator name without "admin"/"administrator".
- [ ] No passwords in Dockerfiles or Git; `.env` used; secrets for confidential data.
- [ ] Domain `jbrosio.42.fr` points to the local IP.
- [ ] `README.md`, `USER_DOC.md` and `DEV_DOC.md` at the repository root.
