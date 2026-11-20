FROM debian:bookworm

# Instalamos NGINX y OpenSSL
RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Creamos la carpeta para los certificados
RUN mkdir -p /etc/nginx/ssl

# Generamos el certificado SSL auto-firmado directamente durante el build.
# Reemplaza 'tu_login' al final de la línea.
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/inception.key \
    -out /etc/nginx/ssl/inception.crt \
    -subj "/C=ES/ST=Andalucia/L=Malaga/O=42/OU=42/CN=tu_login.42.fr/UID=tu_login"

# Copiamos nuestro archivo de configuración para sobreescribir el de por defecto
COPY conf/nginx.conf /etc/nginx/conf.d/default.conf

# Exponemos el puerto de acceso
EXPOSE 443

# Arrancamos NGINX en primer plano (daemon off) para que el contenedor no muera
ENTRYPOINT ["nginx", "-g", "daemon off;"]
