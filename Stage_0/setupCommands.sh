#!/bin/bash
apt update
apt dist-upgrade -y
apt autoremove -y
reboot

# Steps to add Laravel requirements

## Make sure we are using the latest postgres
echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 7FCC7D46ACCC4CF8

apt update

apt install -y postgresql postgresql-client postgresql-contrib

## Make sure we are using the latest redis
add-apt-repository -y ppa:chris-lea/redis-server
apt update

apt install -y redis

## Make sure we will get the latest PHP
add-apt-repository -y ppa:ondrej/php
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 4F4EA0AAE5267A6C

apt update

apt install -y php8.0 php8.0-cli php8.0-fpm \
      php8.0-bcmath \
      php8.0-common php8.0-curl \
      php8.0-dev \
      php8.0-gd php8.0-gmp php8.0-grpc \
      php8.0-igbinary php8.0-imagick php8.0-intl \
      php8.0-mcrypt php8.0-mbstring php8.0-mysql \
      php8.0-opcache \
      php8.0-pcov php8.0-pgsql php8.0-protobuf \
      php8.0-redis \
      php8.0-soap php8.0-sqlite3 php8.0-ssh2  \
      php8.0-xml \
      php8.0-zip

## Make sure we will get the latest NGINX
add-apt-repository -y ppa:nginx/stable
apt update
apt install -y nginx

## Install certbot
apt install -y \
  certbot \
  python3-certbot-nginx

cat > /etc/nginx/sites-enabled/default <<- EOM
server {
  listen 80 default_server;
  listen [::]:80 default_server;

  root /var/www/site/public;

  index index.html index.htm index.php;

  server_name _;

  location / {
    try_files \$uri \$uri/ =404;
  }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/fpm.sock;
     }

  location ~ /\.ht {
    deny all;
  }
}
EOM

mkdir -p  /var/www/site/public
echo "hello world" > /var/www/site/public/index.html
chown -R www-data: /var/www/site/public

certbot --nginx -d www.example.com -d example.com

service nginx restart

cd /tmp || exit
sudo -s -u postgres createuser example
sudo -s -u postgres createdb example
echo "alter user example with encrypted password 'example';" | sudo -u postgres psql

## Now once again make sure everything is up to date and restart the server
apt update
apt dist-upgrade -y
apt autoremove -y
reboot
