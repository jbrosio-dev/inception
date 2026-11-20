FROM debian:bookworm

# Instalamos el servidor de MariaDB
RUN apt-get update && apt-get install -y mariadb-server

# Copiamos nuestro archivo de configuración
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

# Copiamos el script de inicialización y le damos permisos de ejecución
COPY tools/init_db.sh /usr/local/bin/init_db.sh
RUN chmod +x /usr/local/bin/init_db.sh

# Exponemos el puerto de la base de datos
EXPOSE 3306

# Ejecutamos el script al arrancar el contenedor
ENTRYPOINT ["/usr/local/bin/init_db.sh"]
