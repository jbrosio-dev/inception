FROM debian:bookworm

# Instalamos el servidor de cache
RUN apt-get update && apt-get install -y redis-server && rm -rf /var/lib/apt/lists/*

# Copiamos nuestra configuracion personalizada
COPY conf/redis.conf /etc/redis/redis.conf

EXPOSE 6379

# Arrancamos Redis leyendo el archivo que acabamos de copiar
CMD ["redis-server", "/etc/redis/redis.conf"]