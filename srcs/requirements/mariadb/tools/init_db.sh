#!/bin/bash

set -e

SQL_PASSWORD="$(cat /run/secrets/sql_password)"
SQL_ROOT_PASSWORD="$(cat /run/secrets/sql_root_password)"

# Comprobamos si la base de datos ya existe en el volumen
if [ ! -d "/var/lib/mysql/${SQL_DATABASE}" ]; then
    echo "Inicializando la base de datos..."
    
    # Arrancamos el servicio en segundo plano temporalmente para configurarlo
    service mariadb start
    
    # Le damos un par de segundos para que levante
    sleep 2
    
    # Ejecutamos las consultas SQL usando las variables de entorno
    mysql -e "CREATE DATABASE IF NOT EXISTS \`${SQL_DATABASE}\`;"
    mysql -e "CREATE USER IF NOT EXISTS \`${SQL_USER}\`@'%' IDENTIFIED BY '${SQL_PASSWORD}';"
    mysql -e "GRANT ALL PRIVILEGES ON \`${SQL_DATABASE}\`.* TO \`${SQL_USER}\`@'%';"
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${SQL_ROOT_PASSWORD}';"
    mysql -e "FLUSH PRIVILEGES;"
    
    # Apagamos el servicio temporal de forma segura
    mysqladmin -u root -p${SQL_ROOT_PASSWORD} shutdown
fi

echo "Iniciando MariaDB en primer plano..."

exec mysqld_safe