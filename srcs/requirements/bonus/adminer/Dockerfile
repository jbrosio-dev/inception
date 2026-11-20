FROM debian:bookworm

# Instalamos dependencias: wget para descargar y PHP con soporte para MySQL
RUN apt-get update && apt-get install -y \
	wget \
	php8.2-cli \
	php8.2-mysql \
	&& rm -rf /var/lib/apt/lists/*

# Creamos la carpeta donde vivira la web
RUN mkdir -p /var/www/adminer

# Descargamos la version estable de Adminer
RUN wget "https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php" -O /var/www/adminer/index.php

# Exponemos el puerto para el servidor web de PHP
EXPOSE 8080

# Ejecutamos el servidor web integrado de PHP apuntando a nuestra carpeta
CMD ["php", "-S", "0.0.0.0:8080", "-t", "/var/www/adminer"]