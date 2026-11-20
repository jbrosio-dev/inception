FROM debian:bookworm

RUN apt-get update && apt-get install -y vsftpd && rm -rf /var/lib/apt/lists/*

COPY conf/vsftpd.conf /etc/vsftpd.conf
COPY tools/ftp_start.sh /usr/local/bin/ftp_start.sh
RUN chmod +x /usr/local/bin/ftp_start.sh

# Exponemos el puerto estándar 21 y el rango pasivo
EXPOSE 21 21100-21110

ENTRYPOINT ["/usr/local/bin/ftp_start.sh"]