#!/bin/bash

set -e

SQL_PASSWORD="$(cat /run/secrets/sql_password)"
WP_ADMIN_PASS="$(cat /run/secrets/wp_admin_password)"
WP_USER_PASS="$(cat /run/secrets/wp_user_password)"

# Creamos el directorio si no existe (el volumen montado)
mkdir -p /var/www/wordpress
cd /var/www/wordpress

# Comprobamos si WordPress ya está instalado
if [ ! -f "wp-config.php" ]; then
    echo "Descargando WordPress..."
    wp core download --allow-root

    echo "Configurando la conexión a la base de datos..."

    echo "Esperando conexión en el puerto 3306 de MariaDB..."
    while ! </dev/tcp/mariadb/3306 2>/dev/null; do
        sleep 2
    done
    echo "¡Puerto 3306 abierto! Continuando..." 
    
    wp config create --dbname="${SQL_DATABASE}" \
                     --dbuser="${SQL_USER}" \
                     --dbpass="${SQL_PASSWORD}" \
                     --dbhost="mariadb:3306" \
                     --allow-root

    echo "Instalando WordPress y creando el usuario administrador..."
    wp core install --url="${DOMAIN_NAME}" \
                    --title="Inception 42" \
                    --admin_user="${WP_ADMIN_USER}" \
                    --admin_password="${WP_ADMIN_PASS}" \
                    --admin_email="${WP_ADMIN_EMAIL}" \
                    --allow-root

    echo "Creando el segundo usuario (Autor)..."
    wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
                   --role=author \
                   --user_pass="${WP_USER_PASS}" \
                   --allow-root
    
    echo "Configurando Redis en WordPress..."
    # Inyectamos las credenciales de Redis en el wp-config.php
    wp config set WP_REDIS_HOST redis --allow-root
    wp config set WP_REDIS_PORT 6379 --raw --allow-root
    wp config set WP_CACHE true --raw --allow-root
    
    # Descargamos el plugin, lo activamos y encendemos la conexión
    wp plugin install redis-cache --activate --allow-root
    wp redis enable --allow-root
    
    # Ajustamos los permisos para el servidor web
    chown -R www-data:www-data /var/www/wordpress
fi

echo "Iniciando PHP-FPM en primer plano..."

mkdir -p /run/php

exec php-fpm8.2 -F