FROM debian:bookworm

# Instalamos curl y certificados para poder descargar de forma segura
RUN apt-get update && apt-get install -y curl ca-certificates tar && rm -rf /var/lib/apt/lists/*

# Descargamos el binario de Portainer y lo extraemos en la raíz
RUN curl -L https://github.com/portainer/portainer/releases/download/2.19.4/portainer-2.19.4-linux-amd64.tar.gz -o portainer.tar.gz \
    && tar -xvf portainer.tar.gz \
    && rm portainer.tar.gz

# Exponemos el puerto estándar HTTP de Portainer
EXPOSE 9000

# Ejecutamos el binario apuntando a la carpeta de datos
CMD ["/portainer/portainer"]