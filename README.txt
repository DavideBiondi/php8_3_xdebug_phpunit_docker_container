🔧 PHP 8.3 + Xdebug 3.4 + PHPUnit 12 – Ready-to-Use Development Environment

This repository provides a complete Docker-based environment for PHP development, debugging, and automated testing.
It includes PHP 8.3, Xdebug 3.4, PHPUnit 12, and Composer 2.9, all preconfigured and ready to run out of the box.

Step by step guide:

# 1a Pull the image from DockerHub (you will still need the docker-compose.yml file to configure Apache 2.4) ✅️
docker pull davidebiondi/php8_3_xdebug_phpunit:latest

# 1b Or clone this repo itself and build the image ✅️
gh repo clone DavideBiondi/php8_3_xdebug_phpunit_docker_container
cd ~/php8_3_xdebug_phpunit_docker_container
export PROJECT_PATH=/path/to/your/PHP_Project
docker compose up -d

# 2a Create settings.json file ✅️
mkdir -p ~/php8_3_xdebug_phpunit_docker_container/.vscode
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

  apache:
    image: httpd:2.4
    container_name: apache_php8
    ports:
      - "8081:80"
    volumes:
      - ${PROJECT_PATH}:/var/www/html
      - ./httpd.conf:/usr/local/apache2/conf/httpd.conf
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

# 5 Compose the container ✅️
cd ~/php8_3_xdebug_phpunit_docker_container
export PROJECT_PATH=/path/to/your/PHP_Project
docker compose up -d

# 6 Configure Apache
🔧 6.1 Generate Default Apache Configuration
cd ~/php8_3_xdebug_phpunit_docker_container
docker run --rm httpd:2.4 cat /usr/local/apache2/conf/httpd.conf > httpd.conf

🧪 6.2 Apache Configuration Tests

✅ Test 1 – Ensure mod_proxy loads BEFORE mod_proxy_fcgi

Un-comment the lines:
sed -E 's/#(.*mod_proxy\.so)/\1/;s/#(.*mod_proxy_fcgi\.so)/\1/' httpd.conf > httpd.conf.test
diff httpd.conf httpd.conf.test

Expected output:
142c142
< #LoadModule proxy_module modules/mod_proxy.so
---
> LoadModule proxy_module modules/mod_proxy.so
146c146
< #LoadModule proxy_fcgi_module modules/mod_proxy_fcgi.so
---
> LoadModule proxy_fcgi_module modules/mod_proxy_fcgi.so


sed -E -i 's/#(.*mod_proxy\.so)/\1/;s/#(.*mod_proxy_fcgi\.so)/\1/' httpd.conf

Validation test (no output expected):
diff httpd.conf httpd.conf.test

✅️ Test 2 – Change DocumentRoot

sed -E 's/(DocumentRoot) \"\/usr\/local\/apache2\/htdocs\"/\1 \"\/var\/www\/html\/public\"/' httpd.conf > httpd.conf.test
diff httpd.conf httpd.conf.test

Expected output:
265c265
< DocumentRoot "/usr/local/apache2/htdocs"
---
> DocumentRoot "/var/www/html/public"

sed -E -i 's/(DocumentRoot) \"\/usr\/local\/apache2\/htdocs\"/\1 \"\/var\/www\/html\/public\"/' httpd.conf

Validation (no output expected):
diff httpd.conf httpd.conf.test

sed -E 's/(<Directory) \"\/usr\/local\/apache2\/htdocs\">/\1 \"\/var\/www\/html\/public\">/' httpd.conf > httpd.conf.test
diff httpd.conf httpd.conf.test

Expected output:
266c266
< <Directory "/usr/local/apache2/htdocs">
---
> <Directory "/var/www/html/public">

sed -E -i 's/(<Directory) \"\/usr\/local\/apache2\/htdocs\">/\1 \"\/var\/www\/html\/public\">/' httpd.conf

Validation (no output expected):
diff httpd.conf httpd.conf.test

Set "AllowOverride" parameter with value "All":
sed -E '/<Directory "\/var\/www\/html\/public">/,/<\/Directory>/ s/#?\s*(AllowOverride) None/    \1 All/' httpd.conf > httpd.conf.test
diff httpd.conf httpd.conf.test

Expected output:
286c286
<     AllowOverride None
---
>     AllowOverride All

sed -E -i '/<Directory "\/var\/www\/html\/public">/,/<\/Directory>/ s/#?\s*(AllowOverride) None/    \1 All/' httpd.conf

Validation (no output expected):
diff httpd.conf httpd.conf.test

✅ Test 3 – Add PHP-FPM Handler

sed -i '/Listen 80/ a <FilesMatch \\.php$>\n    SetHandler \"proxy:fcgi:\/\/php8.3:9000\"\n<\/FilesMatch>' httpd.conf.test
Append a newline after a pattern:
sed -i '/Listen 80/{G;}' httpd.conf.test
diff httpd.conf httpd.conf.test

Expected output:
53a54,57
> <FilesMatch \.php$>
>     SetHandler "proxy:fcgi://php8.3:9000"
> </FilesMatch>
> 

sed -i '/Listen 80/ a <FilesMatch \\.php$>\n    SetHandler \"proxy:fcgi:\/\/php8.3:9000\"\n<\/FilesMatch>' httpd.conf
sed -i '/Listen 80/{G;}' httpd.conf

Validation (no output expected):
diff httpd.conf httpd.conf.test

✅ Test 4 – Ensure DirectoryIndex includes index.php and index.htm

sed -i -E 's/(DirectoryIndex) (index.html)/\1 index.php index.htm \2/' httpd.conf.test
diff httpd.conf httpd.conf.test

Expected output:
303c303
<     DirectoryIndex index.html
---
>     DirectoryIndex index.php index.htm index.html

sed -i -E 's/(DirectoryIndex) (index.html)/\1 index.php index.htm \2/' httpd.conf

Validation (no output expected):
diff httpd.conf httpd.conf.test

✅ Test 5 – Load mod_expires module

sed -E 's/#(.*mod_expires\.so)/\1/' httpd.conf > httpd.conf.test
diff httpd.conf httpd.conf.test

Expected output:
138c138
< #LoadModule expires_module modules/mod_expires.so
---
> LoadModule expires_module modules/mod_expires.so

sed -E -i 's/#(.*mod_expires\.so)/\1/' httpd.conf

Validation (no output expected):
diff httpd.conf httpd.conf.test

✅ Test 6 – Load mod_rewrite module

sed -E 's/#(.*mod_rewrite\.so)/\1/' httpd.conf > httpd.conf.test
diff httpd.conf httpd.conf.test

Expected output:
203c203
< #LoadModule rewrite_module modules/mod_rewrite.so
---
> LoadModule rewrite_module modules/mod_rewrite.so

sed -E -i 's/#(.*mod_rewrite\.so)/\1/' httpd.conf

Validation (no output expected):
diff httpd.conf httpd.conf.test

# 7 Restart the apache server

docker restart apache_php8

Expected output:
apache_php8

# 8 Build a custom bridge network ✅️
docker network create \
  --driver=bridge \
  --subnet=172.25.0.0/16 \
  --gateway=172.25.0.1 \
  --opt com.docker.network.bridge.name=br-xdebug \
  --opt com.docker.network.bridge.enable_ip_masquerade=false \
  --opt com.docker.network.bridge.enable_icc=true \
  --opt com.docker.network.driver.mtu=1500 \
  my_xdebug_net


# 9 Configure the xdebug configuration file ✅️
docker exec -it php8.3 bash

# 9.1 Inside the container ✅️
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

# 10 Configure UFW (firewall) ✅️
sudo ufw allow from 172.25.0.0/16 to any port 9003 proto tcp
sudo ufw allow in on br-xdebug
sudo ufw restart

# 11 Configure the launch.json file in your php project ✅️
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

# 12 🧪 Runtime Verification Tests

✅️ Test 1 - Check container is running
docker ps | grep apache

Expected output:
alpha_num_code   httpd:2.4               "httpd-name"       34 seconds ago   Up 34 seconds

✅️ Test 2 - Check Apache logs
docker logs apache_php8

Expected output:
Apache/2.4.66 (Unix) configured -- resuming normal operations

✅️ Test 3 - Check Port Binding via Host
ss -lntp | grep 8081

Expected output:
LISTEN 0.0.0.0:8081

netstat -lntp | grep 8081

Expected output:
tcp        0      0 0.0.0.0:8081            0.0.0.0:*               LISTEN      -                   

✅️ Test 4 - Check Apache is listening

docker exec apache_php8 apachectl -S

Expected output:
Main DocumentRoot: "/var/www/html/public"

docker exec -it apache_php8 apachectl -t

Expected output:
Syntax OK

✅️ Test 5 - Check index.php existence

docker exec apache_php8 ls /var/www/html/index.php

Expected output:
/var/www/html/index.php

✅️ Test 6 - Test via curl

curl http://localhost:8081/index.php

Expected output:
HTML output (PHP executed, not downloaded)
