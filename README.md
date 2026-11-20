# Inception

## Description

**Inception** is a System Administration project. The goal is to build a small, self-contained web infrastructure using **Docker** and **Docker Compose**, running inside a virtual machine. Every service is built from its own hand-written `Dockerfile` on top of **Debian Bookworm** (no pre-built images from DockerHub), runs in a dedicated container and communicates through a dedicated Docker network (`inception_net`).

### Mandatory services

| Service     | Role                                                                 |
|-------------|----------------------------------------------------------------------|
| `nginx`     | Only entrypoint of the infrastructure. HTTPS on port **443**, TLSv1.2 / TLSv1.3 only. |
| `wordpress` | WordPress + PHP-FPM (no web server inside), configured with WP-CLI.  |
| `mariadb`   | MariaDB database server (no web server inside).                      |

### Bonus services

| Service      | Role                                                                                      | Port(s)         |
|--------------|-------------------------------------------------------------------------------------------|-----------------|
| `redis`      | Object cache for WordPress (20 MB, `allkeys-lru`), enabled through the `redis-cache` plugin. | 6379 (internal) |
| `ftp`        | `vsftpd` server, chrooted in the WordPress volume. Password injected via Docker secret.   | 21, 21100-21110 |
| `adminer`    | Lightweight web UI for MariaDB, served by PHP's built-in server.                           | 8080            |
| `static_web` | Static portfolio (HTML/CSS/JS, **no PHP**) served by `lighttpd`.                           | 1337            |
| `portainer`  | Web dashboard to monitor and manage containers, networks and volumes (service of my choice). | 9000          |

### Persistent data

Two Docker **named volumes** store the persistent data, both located under `/home/jbrosio/data` on the host:

- **MariaDB volume** → the WordPress database.
- **WordPress volume** → the WordPress website files (shared with NGINX and the FTP server).

## Instructions

### Prerequisites

- A Linux virtual machine with **Docker Engine** and the **Docker Compose** plugin.
- `make` and `git`.
- `sudo` rights (to edit `/etc/hosts` and create the data folders).

### Setup

1. Clone the repository and enter it.
2. Point the domain name to your local IP:
   ```bash
   echo "127.0.0.1 jbrosio.42.fr" | sudo tee -a /etc/hosts
   ```
3. Create the secrets (see `DEV_DOC.md` for the full list). They are **never** committed to Git.
4. Create `srcs/.env` with the non-confidential variables (domain name, database name, usernames, e-mails...). See `DEV_DOC.md`.

### Build and run

```bash
make          # build the images and start the whole stack
make down     # stop the stack
make clean    # stop and remove containers/networks
make fclean   # clean everything, including volumes and data
make re       # rebuild from scratch
```

### Access

| What                | URL                                  |
|---------------------|--------------------------------------|
| WordPress website   | https://jbrosio.42.fr                |
| WordPress admin     | https://jbrosio.42.fr/wp-admin       |
| Adminer             | http://jbrosio.42.fr:8080            |
| Static website      | http://jbrosio.42.fr:1337            |
| Portainer           | http://jbrosio.42.fr:9000            |
| FTP                 | `ftp jbrosio.42.fr 21` (passive ports 21100-21110) |

The browser will warn about the self-signed TLS certificate; this is expected.

More details: [`USER_DOC.md`](USER_DOC.md) (usage) and [`DEV_DOC.md`](DEV_DOC.md) (development).

## Project description

### Use of Docker and included sources

All configuration lives in the `srcs/` folder, and the `Makefile` at the root of the repository drives `docker compose` to build the images and start the application.

```
.
├── Makefile
├── secrets/                  # local only, ignored by Git
└── srcs/
    ├── docker-compose.yml
    ├── .env                  # local only, ignored by Git
    └── requirements/
        ├── nginx/            # Dockerfile, conf/, tools/
        ├── wordpress/        # Dockerfile, tools/wp_install.sh
        ├── mariadb/          # Dockerfile, tools/init_db.sh
        └── bonus/
            ├── redis/
            ├── ftp/          # tools/ftp_start.sh
            ├── adminer/
            ├── static_web/   # html/index.html
            └── portainer/
```

- Each image has the same name as its service, and each service runs in its own container.
- Containers restart automatically after a crash.
- Each container's main process runs in the foreground as PID 1 (`exec php-fpm8.2 -F`, `exec mysqld_safe`, `exec vsftpd ...`), with no `tail -f`, `sleep infinity` or infinite loops.
- Initialization scripts are idempotent: they check whether MariaDB or WordPress is already installed in the volume before configuring anything, so restarts don't wipe data.
- Passwords are read from Docker secrets (`/run/secrets/...`) at runtime. No password is written in any Dockerfile.

### Design choices

- **Debian Bookworm** as the base image for all services (penultimate stable Debian release, as required by the subject).
- **WP-CLI** automates WordPress installation: it creates the administrator (whose name does not contain "admin") and a second user with the `author` role.
- The WordPress container waits for MariaDB's port 3306 to be open before installing, avoiding race conditions at startup.
- **NGINX is the only entrypoint of the mandatory part** (port 443, TLSv1.2/1.3). Bonus services open extra ports as allowed by the subject.
- **Redis** is capped at 20 MB with an LRU policy to avoid exhausting host memory.
- **Adminer** runs on PHP's built-in server instead of Apache/NGINX, keeping the container minimal.
- **Portainer** was chosen as the free-choice bonus because it makes it easy to inspect and debug the whole stack visually. Note that it mounts the Docker socket, which grants it broad control over the host's Docker daemon, so it should only be used in a local/dev environment.

### Comparisons

#### Virtual Machines vs Docker

| | Virtual Machine | Docker |
|---|---|---|
| Isolation | Full OS with its own kernel, isolated by a hypervisor | Processes isolated with namespaces/cgroups, **sharing the host kernel** |
| Size / startup | Gigabytes, boots in minutes | Megabytes, starts in seconds |
| Resource usage | High (full OS per VM) | Low |
| Use case | Running different OSes, strong isolation | Packaging and deploying single applications reproducibly |

In this project a VM is the host environment, and Docker runs the services inside it.

#### Secrets vs Environment Variables

| | Environment variables | Docker secrets |
|---|---|---|
| Storage | In the container's environment (visible with `docker inspect`, `env`) | Mounted as files in `/run/secrets/` (in-memory, read-only) |
| Best for | Non-sensitive config (domain name, DB name, usernames) | Passwords and any confidential data |
| Risk | May leak through logs, inspection or child processes | Much lower exposure |

This project uses a `.env` file for general configuration and **Docker secrets** for every password (database, root, WordPress users, FTP).

#### Docker Network vs Host Network

| | Docker (bridge) network | Host network |
|---|---|---|
| Isolation | Containers get their own network namespace and private IPs | Container shares the host's network stack |
| Service discovery | Containers reach each other by service name (e.g. `mariadb:3306`) | None built in |
| Port exposure | Only explicitly published ports are reachable | Every port the container opens is exposed on the host |

`network: host`, `--link` and `links:` are forbidden by the subject. The custom `inception_net` network lets services talk by name while only the intended ports are published.

#### Docker Volumes vs Bind Mounts

| | Named volumes | Bind mounts |
|---|---|---|
| Managed by | Docker | The user (arbitrary host path) |
| Portability | High, independent of host folder layout | Depends on the host's directory structure |
| Permissions | Handled by Docker | Subject to host UID/GID and permissions |
| Subject rule | **Required** for the WordPress and database data | Not allowed for those two volumes |

The two named volumes store their data in `/home/jbrosio/data` on the host. The Docker socket mount used by Portainer is a bind mount, but it is not one of the persistent data volumes covered by the rule.

## Resources

### References

- Docker documentation: https://docs.docker.com/
- Dockerfile best practices: https://docs.docker.com/build/building/best-practices/
- Docker Compose file reference: https://docs.docker.com/reference/compose-file/
- Docker secrets: https://docs.docker.com/engine/swarm/secrets/
- NGINX documentation (including `ngx_http_ssl_module`): https://nginx.org/en/docs/
- WP-CLI handbook: https://make.wordpress.org/cli/handbook/
- MariaDB Knowledge Base: https://mariadb.com/kb/en/
- Redis Object Cache plugin: https://wordpress.org/plugins/redis-cache/
- vsftpd manual: https://security.appspot.com/vsftpd.html
- Adminer: https://www.adminer.org/
- lighttpd documentation: https://redmine.lighttpd.net/projects/lighttpd/wiki
- Portainer documentation: https://docs.portainer.io/

### Use of AI

AI (Claude) was used as a support tool, following the subject's AI guidelines:

- **Documentation:** generating the first drafts of `README.md`, `USER_DOC.md` and `DEV_DOC.md` from the project's source files and the subject. All content was reviewed and checked against the actual project by the author.

