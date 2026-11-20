# User Documentation

This guide explains, in simple terms, how to use the Inception stack as an end user or administrator.

## 1. Services provided

| Service      | What it does                                                         | How to reach it                    |
|--------------|----------------------------------------------------------------------|------------------------------------|
| **NGINX**    | Secure entrypoint (HTTPS, TLS 1.2/1.3) to the WordPress site.        | https://jbrosio.42.fr              |
| **WordPress**| The website and its administration panel.                            | https://jbrosio.42.fr/wp-admin     |
| **MariaDB**  | Database that stores the website content and users. Internal only.   | Not directly reachable             |
| **Redis**    | Speeds up WordPress by caching data in memory. Internal only.        | Not directly reachable             |
| **FTP**      | Upload files (themes, plugins, images) to the WordPress folder.      | `jbrosio.42.fr`, port 21           |
| **Adminer**  | Web interface to browse and manage the database.                     | http://jbrosio.42.fr:8080          |
| **Static website** | A static portfolio page.                                       | http://jbrosio.42.fr:1337          |
| **Portainer**| Web dashboard to monitor containers, networks and volumes.           | http://jbrosio.42.fr:9000          |

## 2. Start and stop the project

All commands are run from the root of the repository.

| Action                                   | Command        |
|------------------------------------------|----------------|
| Start everything (build if needed)       | `make`         |
| Stop the project (data is kept)          | `make down`    |
| Stop and remove containers and networks  | `make clean`   |
| Remove everything, **including data**    | `make fclean`  |
| Rebuild everything from scratch          | `make re`      |

> ⚠️ `make fclean` deletes the volumes and the data stored in `/home/jbrosio/data`. Use it only if you want to start over.

## 3. Access the website and the administration panel

1. Make sure your machine resolves the domain name. The line below must exist in `/etc/hosts`:
   ```
   127.0.0.1 jbrosio.42.fr
   ```
2. Open **https://jbrosio.42.fr** in your browser. The certificate is self-signed, so the browser will show a warning: accept it to continue.
3. For the administration panel, go to **https://jbrosio.42.fr/wp-admin** and log in with the administrator account.

There are two WordPress accounts:

- **Administrator**: full control of the site (its username does not contain the word "admin").
- **Author**: can write and publish their own posts.

### Other interfaces

- **Adminer** (http://jbrosio.42.fr:8080): choose *MySQL* as system, server `mariadb`, and enter the database user, password and database name.
- **Portainer** (http://jbrosio.42.fr:9000): on first access, create the admin account when prompted.
- **FTP**: connect with an FTP client to `jbrosio.42.fr` port 21 using the FTP username and password. You will be placed in the WordPress folder and cannot leave it. Use passive mode.

## 4. Locate and manage credentials

Credentials are stored **locally** and are never committed to Git.

| Where                | What it contains                                                                 |
|----------------------|----------------------------------------------------------------------------------|
| `secrets/` (root)    | Passwords, one file per secret: database user, database root, WordPress admin, WordPress author, FTP. |
| `srcs/.env`          | Non-confidential settings: domain name, database name, usernames, e-mails.       |

To change a password:

1. Edit the corresponding file in `secrets/`.
2. Recreate the data, since passwords are applied only on first initialization: run `make fclean` followed by `make`. **This erases the existing data.**

Alternatively, change WordPress user passwords from the admin panel (*Users → Profile*) without losing data.

## 5. Check that the services are running correctly

**List containers and their state** (all should be `Up`):

```bash
docker compose -f srcs/docker-compose.yml ps
```

**Check the logs** of a service if something looks wrong:

```bash
docker compose -f srcs/docker-compose.yml logs <service>      # e.g. nginx, wordpress, mariadb
```

**Quick checks:**

| Check                         | How                                                                 |
|-------------------------------|---------------------------------------------------------------------|
| Website responds over HTTPS   | `curl -k https://jbrosio.42.fr` returns HTML                         |
| TLS version                   | `openssl s_client -connect jbrosio.42.fr:443 -tls1_2` succeeds       |
| Port 80 is closed             | `curl http://jbrosio.42.fr` fails to connect                         |
| Database is up                | Adminer login works                                                  |
| Cache works                   | In WordPress: *Settings → Redis* shows status **Connected**          |
| All containers visible        | Portainer dashboard shows every container as *running*               |

If a container keeps restarting, read its logs: the cause is usually a missing secret or a wrong value in `srcs/.env`.
