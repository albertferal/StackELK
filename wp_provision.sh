#!/bin/bash

                            ########## DISCO MARIADB ##########

# Comprobar si se está ejecutando como root
if [ "$(id -u)" -ne 0 ]; then
    echo "Este script debe ejecutarse como root o con privilegios sudo"
    exit 1
fi

# Actualización de repositorios
apt update

# Instalación de parted y lvm2 en caso de que no estén instalados
apt install -y parted lvm2

# Crear partición y sistema de archivos para la base de datos MariaDB
parted /dev/sdc mklabel gpt
parted /dev/sdc mkpart primary ext4 0% 100%
pvcreate /dev/sdc1
vgcreate wp_vg_data /dev/sdc1

# Crear un volumen lógico que abarcará todo el espacio disponible en "wp_vg_data"
lvcreate -l 100%FREE -n lv_mysql wp_vg_data

# Crear un sistema de archivos ext4 en el LV
mkfs.ext4 /dev/mapper/wp_vg_data-lv_mysql

# Crear el directorio dónde se almacenarán los datos de MariaDB
mkdir /var/lib/mysql

# Añadir entrada al archivo /etc/fstab para montar automáticamente el LV en el directorio /var/lib/mysql.
echo '/dev/mapper/wp_vg_data-lv_mysql /var/lib/mysql ext4 defaults 0 0' | sudo tee -a /etc/fstab
mount -a


                    ########## INSTALACIÓN NGINX, MARIADB Y PHP ##########


# Actualización de Repositorios
apt update

# Eliminar la carpeta lost+found para evitar errores al instalar el software
rm -rf /var/lib/mysql/lost+found

# Eliminar Instancias Anteriores de MariaDB (en caso de que existan)
apt remove -y mariadb-server mariadb-common
apt purge -y mariadb-server mariadb-common

# Instalación de Nginx, MariaDB y PHP
apt install -y nginx mariadb-server mariadb-common php-fpm php-mysql expect php-curl php-gd php-intl php-mbstring php-soap php-xml php-xmlrpc php-zip

# Configuración de Nginx
cat <<EOF > /etc/nginx/sites-available/wordpress
# Managed by installation script- Do not change
server {
    listen 80;
    root /var/www/wordpress;
    index index.php index.html index.htm index.nginx-debian.html;
    server_name localhost;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock; # Cambio de versión de PHP
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

# Crear enlace simbólico al directorio /etc/nginx/sites-enabled/
# Eliminar el archivo de configuración predeterminado de Nginx para evitar conflictos.
ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default

# Habilitar servicios de Nginx y PHP-FPM
systemctl enable nginx php8.1-fpm # Cambio de versión de PHP
systemctl start nginx php8.1-fpm # Cambio de versión de PHP

# Cambiar permisos para el usuario de MariaDB
chown -R mysql:mysql /var/lib/mysql

# Securizar MariaDB
mysql --user=root <<_EOF_
SET PASSWORD FOR 'root'@'localhost' = PASSWORD('1234');
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
_EOF_

# Crear base de datos y usuario para Wordpress
mysql -u root <<MYSQL_SCRIPT
CREATE DATABASE wordpress DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
GRANT ALL ON wordpress.* TO 'wordpressuser'@'localhost' IDENTIFIED BY 'keepcoding';
FLUSH PRIVILEGES;
MYSQL_SCRIPT


                        ########## INSTALACIÓN WORDPRESS ##########


sudo apt update
sudo apt -y upgrade

# Cambiar de directorio y descargar e instalar Wordpress
cd /var/www/
wget https://wordpress.org/latest.tar.gz

# Descomprimir el archivo y cambiar el propietario y grupo de directorio
tar -xzvf latest.tar.gz
#chown -R www-data:www-data /var/www/wordpress/

# Configurar wp-config.php
mv /var/www/wordpress/wp-config-sample.php /var/www/wordpress/wp-config.php
sed -i 's/database_name_here/wordpress/' /var/www/wordpress/wp-config.php
sed -i 's/username_here/wordpressuser/' /var/www/wordpress/wp-config.php
sed -i 's/password_here/keepcoding/' /var/www/wordpress/wp-config.php

# Asegurarse de que el directorio es propiedad de www-data
chown -R www-data:www-data /var/www/wordpress

# Reiniciar Nginx
systemctl restart nginx


                        ########## INSTALACIÓN FILEBEAT ##########


# Instalación de Filebeat
# Descargar la clave pública de Elasticsearch y la añadirla al sistema de claves.
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" > /etc/apt/sources.list.d/elastic-7.x.list

# Actualizar paquetes e instalar Filebeat
apt update
apt install -y filebeat

# Habilitar módulos de Filebeat
filebeat modules enable system
filebeat modules enable nginx

# Configurar Filebeat
cat <<EOF > /etc/filebeat/filebeat.yml
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/*.log
    - /var/log/nginx/*.log
    - /var/log/mysql/*.log

output.logstash:
  hosts: ["192.168.105.21:5044"]
EOF

# Habilitar y arrancar servicio de Filebeat para recolectar logs imnediatamente
systemctl enable filebeat --now