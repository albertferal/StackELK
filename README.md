# Sysadmin - Albert Fernández
### Este proyecto Vagrant proporciona un entorno de desarrollo para desplegar una instancia de WordPress y un stack ELK (Elasticsearch, Logstash, Kibana) en distintas máquinas virtuales.

## Requisitos
- Vagrant
- VirtualBox

### Configuración
El archivo Vagrantfile está configurado para crear dos máquinas virtuales: una para WordPress y otra para ELK Stack. A continuación se detallan las configuraciones:

## WordPress:
- Box: Ubuntu Jammy64
- Hostname: wordpress
- Dirección IP: 192.168.105.20
- Puerto de Reenvío: 8080 (80 de la máquina virtual a 8080 del host)
- Recursos de la Máquina:
    - 2048 MB de RAM
    - 1 CPU
    - Disco Extra de 2 GB adjunto en el puerto 2 del controlador SCSI
## ELK Stack:
- Box: Ubuntu Jammy64
- Hostname: elk
- Dirección IP: 192.168.105.21
- Puertos de Reenvío:
- 9200 (9200 de la máquina virtual a 9200 del host)
- 5601 (5601 de la máquina virtual a 5601 del host)
- Recursos de la Máquina:
    - 8192 MB de RAM
    - 2 CPUs
    - Disco Extra de 16 GB adjunto en el puerto 2 del controlador SCSI

## Uso:
Asegúrate de tener Vagrant y VirtualBox instalados en tu sistema.
Clona este repositorio y navega al directorio.
Ejecuta ```vagrant up``` para crear y provisionar las máquinas virtuales.

## Aprovisionamiento
Cada máquina virtual se configura mediante scripts de shell. A continuación se mencionan los scripts de aprovisionamiento:

## WordPress
### Consta de un script de aprovisionamiento dividido en 4 fases
- Disco MariaDB: ``Configura el disco extra.``
    - Automatizamos el proceso de configuración de la partición y sistema de archivos para MariaDB en un disco específico (/dev/sdc). Asegúrate de tener una copia de seguridad de tus datos antes de ejecutar este script, ya que implica manipulación de discos y particiones.
- Instalación Nginx, MariaDB y PHP: ``Instala y configura Nginx, MariaDB y PHP.``
    - Configuramos un servidor para alojar WordPress con Nginx, MariaDB y PHP. Recuerda que es importante tener una copia de seguridad de tus datos antes de ejecutar este script, ya que implica manipulación de configuraciones y bases de datos.
- Instalación Wordpress: ``Descarga e instala WordPress.``
    - Instalamos y configuramos WordPress en el servidor, incluyendo la configuración del archivo de configuración wp-config.php. Una vez que se ejecute este script, deberías tener un entorno funcional de WordPress listo para ser utilizado. Recuerda mantener siempre copias de seguridad de tus datos antes de realizar cambios importantes en tu sistema.
    Para empezar a configurar Wordpress podremos acceder a traves de de la URL: ``http://localhost:8080``.
- Instalación Filebeat: ``Instala y configura Filebeat.``
    - Instalamos y configuramos Filebeat para el envío de logs a un servidor Logstash. Una vez ejecutado, Filebeat comenzará a recolectar logs de los archivos especificados y los enviará al servidor Logstash configurado. Recuerda que es importante configurar adecuadamente Logstash para procesar estos logs.

## ELK Stack
### Consta de un script de aprovisionamiento dividido en 4 fases
- Disco Elasticsearch: ``Configura el disco de almacenamiento extra.``
    - Al igual que en la MV wordpress, se automatiza la configuración del espacio de almacenamiento, esta vez para Elasticsearch, en una máquina virtual. Asegúrate de tener una copia de seguridad de tus datos antes de ejecutar este script, ya que implica manipulación de discos y particiones.
- Configuración Elasticsearch: ``Instala y configura Elasticsearch.``
    - Instalamos y configuramos Elasticsearch en el sistema, así como la generación y exportación de contraseñas para los usuarios ``elastic`` y ``kibana_system``. Recuerda que es importante mantener las contraseñas de manera segura y no compartirlas públicamente.
- Configuración Kibana: ``Instala y configura Kibana.``
    - Este script automatiza la instalación y configuración de Kibana en tu sistema. Una vez ejecutado, Kibana debería estar configurado y en funcionamiento, listo para conectarse a Elasticsearch y visualizar los datos. Recuerda que es importante asegurarte de tener configurada correctamente la comunicación segura entre Kibana y Elasticsearch mediante certificados.
- Configuración Logstash: ``Instala y configura Logstash.``
    - Automatizamos la configuración de Logstash y Elasticsearch en tu sistema. Una vez ejecutado, los servicios deberían estar configurados y en funcionamiento, listos para recibir y procesar datos a traves de la URL: ``http://localhost:5601``. Los usuarios y últimas instrucciones se muestran al finalizar el script.

## Claves y usuarios:
- Usuario Elasticsearch: `` elastic ``
- Usuario Kibana: `` kibana_system ``
- Claves Elasticsearch y Kibana:
  - Entraremos en la MV2 con el comando `` vagrant ssh elk ``
  - Una vez dentro ejecutamos `` echo "Clave de elastic: $ELASTICPASS" ``
  - Hacemos lo mismo para kibana `` echo "Clave de kibana_system: $KIBANAPASS" ``
