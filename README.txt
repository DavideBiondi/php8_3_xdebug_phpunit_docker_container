# 1a Pulling the image from DockerHub ✅️
docker pull davidebiondi/php8_3_xdebug_phpunit:latest

# 1b Or clone this repo itself and build the image ✅️
gh repo clone DavideBiondi/php8_3_xdebug_phpunit_docker_container
cd ~/php8_3_xdebug_phpunit_docker_container
export PROJECT_PATH=/path/to/your/PHP_Project
docker compose up -d

# 2a Create settings.json file ✅️
mkdir -p ~/php8_3_xdebug_phpunit_docker_container/.vscode
cd ~/php8.3-docker
cat ./.vscode/settings.json << 'JSON'
{
  "php.validate.executablePath": "/usr/local/bin/php",
  "phpunit.phpunitExecutablePath": "/usr/local/bin/phpunit",
  "phpunit.args": [
    "--configuration=/var/www/html/phpunit.xml"
  ],
  "phpunit.debug": true
}
JSON

# 3a Create the docker-compose.yml file ✅️
cat docker-compose.yml << 'YML'
services:
  php:
    build: .
    container_name: php8.3
    volumes:
      - ${PROJECT_PATH}:/var/www/html
    ports:
      - "${PHP_PORT}:9000"
    networks:
      - my_xdebug_net

  mysql:
    image: mysql:8.0
    container_name: mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    ports:
      - "${MYSQL_PORT}:3306"
    volumes:
      - mysql_data:/var/lib/mysql
    networks:
      - my_xdebug_net

  phpmyadmin:
    image: phpmyadmin/phpmyadmin
    container_name: phpmyadmin
    restart: always
    environment:
      PMA_HOST: mysql
      PMA_PORT: 3306
    ports:
      - "${PHPMYADMIN_PORT}:80"
    networks:
      - my_xdebug_net

volumes:
  mysql_data:

networks:
  my_xdebug_net:
    external: true
YML

# 3 Create the .env file ✅️
# (modify ports by replacing quotation marks, modify user and passwords according to your preference/configuration, avoiding conflicts with already occupied ports)
cd ~/php8_3_xdebug_phpunit_docker_container
cat > .env << 'ENV'
# --- DATABASE ---
MYSQL_ROOT_PASSWORD=password
MYSQL_DATABASE=testdb
MYSQL_USER=user
MYSQL_PASSWORD=password

# --- APPLICATION ---
DB_HOST=host.docker.internal
DB_NAME=testdb
DB_USER=user
DB_PASS=password

# --- PORTS ---
PHP_PORT=?
MYSQL_PORT=?
PHPMYADMIN_PORT=?
ENV

# 4 Compose the container ✅️
cd ~/php8_3_xdebug_phpunit_docker_container
export PROJECT_PATH=/path/to/your/PHP_Project
docker compose up -d

# 5 Build a custom bridge network ✅️
docker network create \
  --driver=bridge \
  --subnet=172.25.0.0/16 \
  --gateway=172.25.0.1 \
  --opt com.docker.network.bridge.name=br-xdebug \
  --opt com.docker.network.bridge.enable_ip_masquerade=false \
  --opt com.docker.network.bridge.enable_icc=true \
  --opt com.docker.network.driver.mtu=1500 \
  my_xdebug_net

# 6 Configure the xdebug configuration file ✅️
docker exec -it php8.3 bash

# 6.1 Inside the container ✅️
cat > /usr/local/etc/php/conf.d/20-xdebug.ini << 'XDBG'
zend_extension=xdebug.so
xdebug.mode=debug
xdebug.start_with_request=yes
xdebug.client_host=172.25.0.1
xdebug.client_port=9003
xdebug.connect_timeout_ms=10000
xdebug.log=/tmp/xdebug.log
XDBG

mv /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini.disabled

exit

# 7 Configure UFW (firewall) ✅️
sudo ufw allow from 172.25.0.0/16 to any port 9003 proto tcp
sudo ufw allow in on br-xdebug
sudo ufw restart

# 8 Configure the launch.json file in your php project ✅️
# (xdebug extension is buggy so place all the php files in the root directory until they solve the issue)
cat > /path/to/your/PHP_Project/.vscode/launch.json << 'JSON'
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "PHP Xdebug",
      "type": "php",
      "request": "launch",
      "port": 9003,
      "pathMappings": {
        "/var/www/html": "${workspaceFolder}"
      },
    }
  ]
}
JSON
