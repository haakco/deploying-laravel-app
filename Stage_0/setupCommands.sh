#!/bin/bash
apt update
apt -y \
  dist-upgrade \
  -o Dpkg::Options::=--force-confdef \
  -o Dpkg::Options::=--force-confnew
apt -y autoremove
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
apt update

apt install -y php7.4 php7.4-cli php7.4-fpm \
      php7.4-bcmath \
      php7.4-common php7.4-curl \
      php7.4-dev \
      php7.4-gd php7.4-gmp php7.4-grpc \
      php7.4-igbinary php7.4-imagick php7.4-intl \
      php7.4-mcrypt php7.4-mbstring php7.4-mysql \
      php7.4-opcache \
      php7.4-pcov php7.4-pgsql php7.4-protobuf \
      php7.4-redis \
      php7.4-soap php7.4-sqlite3 php7.4-ssh2  \
      php7.4-xml \
      php7.4-zip

## Make sure we will get the latest NGINX
add-apt-repository -y ppa:nginx/stable
apt update

apt install -y nginx

## Install certbot
apt install -y \
  certbot \
  python3-certbot-nginx

apt -y dist-upgrade
apt -y autoremove

cat > /etc/nginx/sites-enabled/default <<- EOM
server {
  listen 80 default_server;
  listen [::]:80 default_server;

  root /var/www/site/public;

  index index.html index.htm index.php;

  server_name _;

  location / {
    try_files \$uri \$uri/ /index.php?q=\$uri&\$args;
  }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php-fpm.sock;
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

sudo -s -u postgres createuser user_example
sudo -s -u postgres createdb db_example
echo "alter user user_example with encrypted password 'password_example';" | sudo -u postgres psql
echo "grant all privileges on database db_example to user_example;" | sudo -u postgres psql

## Now once again make sure everything is up to date and restart the server
apt update
apt dist-upgrade -y
apt autoremove -y

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php --install-dir=/bin --filename=composer
php -r "unlink('composer-setup.php');"

sudo -s -u www-data composer

ssh-keygen -t ed25519 -a 100 -f ~/.ssh/id_ed25519 -q -N ""

ssh-keyscan github.com >> ~/.ssh/known_hosts

rm -rf /var/www/site

git clone https://github.com/thedevdojo/wave /var/www/site


cat > /var/www/site/.env <<- EOM
APP_URL=https://srv01.example.com
APP_ENV=production
APP_KEY=base64:8dQ7xw/kM9EYMV4cUkzKgET8jF4P0M0TOmmqN05RN2w=
APP_DEBUG=false

DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=db_example
DB_USERNAME=user_example
DB_PASSWORD=password_example

BROADCAST_DRIVER=log
CACHE_DRIVER=file
SESSION_DRIVER=file
SESSION_LIFETIME=9999
QUEUE_DRIVER=sync

REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

MAIL_DRIVER=smtp
MAIL_HOST=smtp.mailtrap.io
MAIL_PORT=2525
MAIL_USERNAME=
MAIL_PASSWORD=
MAIL_ENCRYPTION=null

PUSHER_APP_ID=
PUSHER_APP_KEY=
PUSHER_APP_SECRET=

JWT_SECRET=Jrsweag3Mf0srOqDizRkhjWm5CEFcrBy

PADDLE_VENDOR_ID=
PADDLE_VENDOR_AUTH_CODE=
PADDLE_ENV=sandbox

WAVE_DOCS=true
WAVE_DEMO=false
WAVE_BAR=true
EOM

chown -R www-data: /var/www/site/.env
chown -R www-data: /var/www/site


cd /var/www/site
sudo su -p -l www-data -s /bin/bash -c "cd /var/www/site && composer install"
sudo su -p -l www-data -s /bin/bash -c "cd /var/www/site && php artisan key:generate"
sudo su -p -l www-data -s /bin/bash -c "cd /var/www/site && php artisan migrate"
sudo su -p -l www-data -s /bin/bash -c "cd /var/www/site && php artisan db:seed"
