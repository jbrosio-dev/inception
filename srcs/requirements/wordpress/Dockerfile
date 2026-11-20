FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    php8.2-fpm \
    php8.2-mysql \
    php8.2-redis \
    curl \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Ruta actualizada a PHP 8.2
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

COPY tools/wp_install.sh /usr/local/bin/wp_install.sh
RUN chmod +x /usr/local/bin/wp_install.sh

EXPOSE 9000

WORKDIR /var/www/wordpress

ENTRYPOINT ["/usr/local/bin/wp_install.sh"]
