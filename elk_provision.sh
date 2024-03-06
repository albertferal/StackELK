#!/bin/bash

                            ########## DISCO ELASTICSEARCH ##########

# Comprobar si se está ejecutando como root
if [ "$(id -u)" -ne 0 ]; then
    echo "Este script debe ejecutarse como root o con privilegios sudo"
    exit 1
fi

# Actualización de repositorios
apt update

# Configuración de puntos de montaje, similar a la MV1
parted /dev/sdc mklabel gpt
parted /dev/sdc mkpart primary ext4 0% 100%
pvcreate /dev/sdc1
vgcreate elk_vg_data /dev/sdc1

# Crear un volumen lógico que abarcará todo el espacio disponible en "elk_vg_data"
lvcreate -l 100%FREE -n lv_elasticsearch elk_vg_data

# Crear un sistema de archivos ext4 en el LV
mkfs.ext4 /dev/mapper/elk_vg_data-lv_elasticsearch

# Crear directorio para elasticsearch
mkdir -p /var/lib/elasticsearch

# Añadir entrada al archivo /etc/fstab para montar automáticamente el LV en el directorio /var/lib/elasticsearch.
echo '/dev/mapper/elk_vg_data-lv_elasticsearch /var/lib/elasticsearch ext4 defaults 0 0' >> /etc/fstab
mount -a


                         ########## CONFIGURACIÓN ELASTICSEARCH ##########


# Actualización de repositorios y paquetes
apt update
apt -y upgrade

# Eliminamos la carpeta lost+found para que no nos de error al instalar el software
rm -rf /var/lib/elasticsearch/lost+found

# Descargar la clave pública de Elasticsearch y la añadimos al sistema de claves
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch |  gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg

# Descargar e instalar los paquetes https
apt-get install apt-transport-https

# Añadir el repo de Elasticsearch y actualizar la lista de paquetes
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" |  tee /etc/apt/sources.list.d/elastic-8.x.list
apt-get update

# Instalacion e inicio de Elasticsearch
apt-get install elasticsearch

# Cambiar propietario y grupo del directorio al usuario y grupo Elasticsearch
chown -R elasticsearch:elasticsearch /var/lib/elasticsearch

# Añadir permisos de escritura para Elasticsearch
chmod go+w /var/lib/elasticsearch

# Habilitar y arrancar el servicio de Elasticsearch
systemctl enable elasticsearch.service --now

# Guardar contraseña Elasticsearch
ELASTICPASS=$( /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic -b -s)
cat << EOF >> /home/vagrant/.bashrc
export ELASTICPASS="$ELASTICPASS"
EOF
echo $ELASTICPASS
# Guardar contrseña Kibana
KIBANAPASS=$( /usr/share/elasticsearch/bin/elasticsearch-reset-password -u kibana_system -b -s)
cat << EOF >> /home/vagrant/.bashrc
export KIBANAPASS="$KIBANAPASS"
EOF
echo $KIBANAPASS


                            ########## CONFIGURACIÓN KIBANA ##########


# Instalacion y configuración de Kibana 
apt-get update
apt install -y kibana

# Configurar certificados
mkdir /etc/kibana/certs/
cp /etc/elasticsearch/certs/http_ca.crt /etc/kibana/certs/

# Configurar kibana.yml
sed -i '6s/#server.port: 5601/server.port: 5601/' /etc/kibana/kibana.yml
sed -i '11s/#server.host: "localhost"/server.host: "0.0.0.0"/' /etc/kibana/kibana.yml
sed -i '43s/#elasticsearch.hosts: \["http:\/\/localhost:9200"\]/elasticsearch.hosts: \["https:\/\/localhost:9200"\]/' /etc/kibana/kibana.yml
sed -i '49s/#//' /etc/kibana/kibana.yml
sed -i '50s/.*//' /etc/kibana/kibana.yml
sed -i "51i\elasticsearch.password: \"$KIBANAPASS\"" /etc/kibana/kibana.yml
sed -i '94s/.*//' /etc/kibana/kibana.yml
sed -i "94i\elasticsearch.ssl.certificateAuthorities: [ \"/etc/kibana/certs/http_ca.crt\" ]" /etc/kibana/kibana.yml

# Habilitar y arrancar kibana
systemctl enable kibana.service --now


                            ########## CONFIGURACIÓN LOGSTASH ##########


# Instalación de Logstash
apt install logstash

# Crear directorio para almacenar los certificados, luego se copian a este nuevo directorio
mkdir /etc/logstash/certs
cp /etc/elasticsearch/certs/http_ca.crt /etc/logstash/certs/

# Cambiar propietario y grupo a logstash
chown -R logstash:logstash /etc/logstash/

# Configuracion de roles en peticion de Logstash
curl -XPOST --cacert /etc/logstash/certs/http_ca.crt -u elastic:"$ELASTICPASS" 'https://localhost:9200/_security/role/logstash_write_role' -H "Content-Type: application/json" -d '
{
"cluster": [
"monitor",
"manage_index_templates"
],
"indices": [
{
"names": [
"*"
],
"privileges": [
"write",
"create_index",
"auto_configure"
],
"field_security": {
"grant": [
"*"
]
}
}
],
"run_as": [],
"metadata": {},
"transient_metadata": {
"enabled": true
}
}'

# Crear usuario de Logstash
curl -XPOST --cacert /etc/logstash/certs/http_ca.crt -u elastic:$ELASTICPASS 'https://localhost:9200/_security/user/logstash' -H "Content-Type: application/json" -d '
{
"password" : "keepcoding_logstash",
"roles" : ["logstash_admin", "logstash_system", "logstash_write_role"],
"full_name" : "Logstash User"
}'


# Crear y configurar los Inputs y Outputs
tee /etc/logstash/conf.d/02-beats-input.conf << EOF
input {
beats {
port => 5044
}
}
EOF

tee /etc/logstash/conf.d/30-elasticsearch-output.conf << EOF
output {
elasticsearch {
hosts => ["https://localhost:9200"]
manage_template => false
index => "filebeat-demo-%{+YYYY.MM.dd}"
user => "logstash"
password => "keepcoding_logstash"
cacert => "/etc/logstash/certs/http_ca.crt"
}
}
EOF

# Habilitar y arrancar servicio Logstash
systemctl enable logstash.service --now

# Mostrar contraseñas en STDOUT para iniciar Elasticsearch y Kibana
echo Instalación finalizada, puedes iniciar la configuración de Elasticsearch en localhost:5601
echo "User para elastic: elastic" >&1
echo "User para kibana: kibana_system " >&1
echo "Para obtener las claves de estos usuarios deberemos seguir las últimas instrucciones del README"

exit 0