# 🌟 Extra Services (Bonus)

This section details the 5 additional services implemented to enrich the infrastructure, optimize performance, and facilitate the management of the Docker environment. 

Each service runs in its own isolated container based on **Debian Bookworm** and integrates seamlessly with the `inception_net` network.

## 1. Redis Cache (`/redis`)
- **Purpose:** Act as an in-memory object cache for WordPress, drastically reducing queries to the MariaDB database and improving load times.
- **Configuration:** Limited to 20MB of RAM with an `allkeys-lru` policy to prevent host saturation. It automatically connects to WordPress via the `redis-cache` plugin installed using WP-CLI.
- **Internal port:** 6379.

## 2. FTP Server (`/ftp`)
- **Purpose:** Allow secure file transfers (themes, plugins, images) directly to the physical WordPress volume from an external client.
- **Technology:** `vsftpd` (Very Secure FTP Daemon).
- **Security:** The user is "jailed" (chroot) in the `/var/www/wordpress` directory. The FTP password is securely injected via **Docker Secrets**.
- **Ports:** 21 (Commands) and 21100-21110 (Passive mode for data transfers in Docker).

## 3. Adminer (`/adminer`)
- **Purpose:** Lightweight web graphical interface to visually manage the MariaDB database without needing to use the command line.
- **Implementation:** Unlike phpMyAdmin, Adminer is a single PHP file. It runs using PHP's built-in web server (`php -S`), without relying on NGINX or Apache.
- **Exposed port:** 8080.

## 4. Static Website (`/static_web`)
- **Purpose:** A static personal portfolio that meets the strict requirement of **not using PHP**.
- **Technology:** `lighttpd`, a web server designed to be extremely fast and consume minimal resources. It serves only plain HTML and CSS files.
- **Exposed port:** 1337.

## 5. Portainer (`/portainer`) - (Service of Choice)
- **Purpose:** Provide an advanced web-based control panel to monitor, manage, and analyze the containers, networks, and volumes of the entire infrastructure in real time.
- **Configuration:** To read the host's state, the Docker socket (`/var/run/docker.sock`) is mapped as a volume (bind mount) into the container.
- **Exposed port:** 9000.