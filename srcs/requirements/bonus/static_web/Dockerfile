FROM debian:bookworm

# Instalamos el servidor web ligero
RUN apt-get update && apt-get install -y lighttpd && rm -rf /var/lib/apt/lists/*

# Copiamos la configuración y el portfolio al contenedor
COPY conf/lighttpd.conf /etc/lighttpd/lighttpd.conf
COPY html/ /var/www/html/

EXPOSE 1337

# Ejecutamos lighttpd en primer plano (-D)
CMD ["lighttpd", "-D", "-f", "/etc/lighttpd/lighttpd.conf"]