#!/bin/bash
set -e

FTP_PASS=$(cat /run/secrets/ftp_password)

# Crear la carpeta de seguridad que vsftpd exige
mkdir -p /var/run/vsftpd/empty

# Crear el usuario FTP si no existe
if ! id -u $FTP_USER > /dev/null 2>&1; then
	echo "Creando usuario FTP: $FTP_USER"
	useradd -m -s /bin/bash $FTP_USER
	echo "$FTP_USER:$FTP_PASS" | chpasswd

	# Le damos los mismos permisos que tienen el servidor web (NGINX/PHP)
	usermod -aG www-data $FTP_USER
fi

# Asegurar que el usuario  sea el dueño de los archivos de WordPress
chown -R $FTP_USER:www-data /var/www/wordpress
chmod -R 775 /var/www/wordpress

echo "Iniciando vsftpd..."
# Reemplazamos el proceso por vsftpd
exec vsftpd /etc/vsftpd.conf