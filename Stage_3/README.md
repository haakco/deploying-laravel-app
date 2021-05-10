# Stage 3: The different stages to learning how to deploy a Laravel App

## Intro

For this stage, we'll move to create docker containers. Having versioned containers makes it simpler, role forward and
backwards. It also gives us a way to test locally on a system that is close to production.

### Pros

* Very repeatable
* Faster from nothing to fully setup
* Can replicate the entire infrastructure for dev or staging.
* Everything documented.

### Cons

* Significantly more complicated.
* Takes longer initially to set up.
* Require knowledge for far more application and moving pieces.

## Assumptions

1. Php code is in git.
1. You are using PostgreSQL.
1. If not, replace the PostgreSQL step with your DB of choice.
1. You have a server.
1. In this example and future ones, we'll be deploying to [DigitalOcean](https://m.do.co/c/179a47e69ec8)
   but the steps should mostly work with any servers.
1. The server is running Ubuntu 20.04
1. You have SSH key pair.
1. Needed to log into your server securely.
1. You have a Domain Name, and you can add entries to point to the server.
1. We'll be using example.com here. Just replace that with your domain of choice.
1. For DNS, I'll be using [Cloudflare](https://www.cloudflare.com/) in these examples.
1. I would recommend using a DNS provider that supports [Terraform](https://www.terraform.io/) and
   [LetsEncrypt](https://community.letsencrypt.org/t/dns-providers-who-easily-integrate-with-lets-encrypt-dns-validation/86438)

## Steps 1: Build Docker Images

For things like the database and Redis, there is no need to build your images.

Though for things like PHP, I find it helps to put precisely what you want into it.

### Base PHP Docker Image

We are going to start by creating a base image for our PHP.

The image will have all the libraries, and we need, and it will have NGINX built in to make our lives easier.

This image will hold everything required except the Laravel code.

We'll then use this image to create our final image for deployment.

We split the images to save us time rebuilding the whole image every time we do a code change.

The final docker file and anything needed to build it can be found
at [```./infra/docker/stage3-docker-ubuntu-php-lv/```](infra/docker/stage3-docker-ubuntu-php-lv)

To make future upgrading easier, we'll use a variable for PHP and Ubuntu versions.

Bellow is the top of our Docker file where we set these.

```dockerfile
ARG BASE_UBUNTU_VERSION='ubuntu:20.04'

FROM ${BASE_UBUNTU_VERSION}

ARG BASE_UBUNTU_VERSION='ubuntu:20.04'
ARG PHP_VERSION='7.4'

ENV DEBIAN_FRONTEND="noninteractive" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US.UTF-8" \
    LC_ALL="C.UTF-8" \
    TERM="xterm" \
    PHP_VERSION="$PHP_VERSION"

RUN echo "PHP_VERSION=${PHP_VERSION}" && \
    echo "UBUNTU_VERSION=${BASE_UBUNTU_VERSION}" && \
    echo ""
```

After this, we follow either the steps we have from any of the earlier stages.

I'm mainly following the installation script we used in Stage_0. (Remember how I said you'd be re-using this)

For reference the installation script is here [```../Stage_0/setupCommands.sh```](../Stage_0/setupCommands.sh)

The one exception is we don't have to generate the SSL certificate, as we'll do that with a proxy that we'll run in
front of the server.

We'll also set some flags to speed up the apt install.

So let's first make sure the Ubuntu is entirely up to date.

We also install some packages to make our lives easier if we want to test anything. e.g. Ping and database clients.

You'll see we also install ```supervisor``` we'll be using this to run our services on start.

You'll see after each run command, we do a cleanup to keep each layer as small as possible.

```dockerfile
## Setting to improve build speed
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
    echo apt-fast apt-fast/maxdownloads string 10 | debconf-set-selections && \
    echo apt-fast apt-fast/dlflag boolean true | debconf-set-selections && \
    echo apt-fast apt-fast/aptmanager string apt-get | debconf-set-selections && \
    echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup && \
    echo "Acquire::http {No-Cache=True;};" > /etc/apt/apt.conf.d/no-cache

## Make sure everything is fully upgraded and shared tooling
RUN apt update && \
    apt -y  \
        dist-upgrade \
        && \
    apt-get install -qy \
        bash-completion \
        ca-certificates \
        inetutils-ping inetutils-tools \
        logrotate \
        mysql-client \
        postgresql-client \
        rsyslog \
        software-properties-common sudo supervisor \
        vim \
        && \
    update-ca-certificates --fresh && \
    apt-get -y autoremove && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/tmp/* && \
    rm -rf /tmp/*
```

Next, we want to install PHP. We also install xdebug but then disable it.

This allows us to enable it for development if we want to.

We also copy and newer xdebug ini that allows remote debugging.

```dockerfile
## Install PHP disable xdebug
RUN add-apt-repository -y ppa:ondrej/php && \
    apt update && \
    apt install -y php${PHP_VERSION} php${PHP_VERSION}-cli php${PHP_VERSION}-fpm \
      php${PHP_VERSION}-bcmath \
      php${PHP_VERSION}-common php${PHP_VERSION}-curl \
      php${PHP_VERSION}-dev \
      php${PHP_VERSION}-gd php${PHP_VERSION}-gmp php${PHP_VERSION}-grpc \
      php${PHP_VERSION}-igbinary php${PHP_VERSION}-imagick php${PHP_VERSION}-intl \
      php${PHP_VERSION}-mcrypt php${PHP_VERSION}-mbstring php${PHP_VERSION}-mysql \
      php${PHP_VERSION}-opcache \
      php${PHP_VERSION}-pcov php${PHP_VERSION}-pgsql php${PHP_VERSION}-protobuf \
      php${PHP_VERSION}-redis \
      php${PHP_VERSION}-soap php${PHP_VERSION}-sqlite3 php${PHP_VERSION}-ssh2  \
      php${PHP_VERSION}-xml php${PHP_VERSION}-xdebug \
      php${PHP_VERSION}-zip \
      && \
    apt -y  \
        dist-upgrade \
        && \
    phpdismod -v ${PHP_VERSION} xdebug && \
    apt-get -y autoremove && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/tmp/* && \
    rm -rf /tmp/*

ADD ./files/php-modules/xdebug.ini /etc/php/${PHP_VERSION}/mods-available/xdebug.ini
ADD ./files/php-modules/igbinary.ini /etc/php/${PHP_VERSION}/mods-available/igbinary.ini
```

Now let us install Nginx. We also remove the default site.

```dockerfile
RUN add-apt-repository -y ppa:nginx/stable && \
    apt update && \
    apt install -y \
        nginx \
      && \
    apt -y  \
        dist-upgrade \
        && \
    apt-get -y autoremove && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/tmp/* && \
    rm -rf /tmp/*
```

We'll need a config for the Nginx server.

For this, we'll create a ```files``` subdirectory directory and add the config files for Nginx in a subdirectory.

[```Stage_3/infra/docker/stage3-docker-ubuntu-php-lv/files/nginx_config```](./infra/docker/stage3-docker-ubuntu-php-lv/files/nginx_config)

One thing to note is that we send the Nginx logs to stdout and stderr, allowing more straightforward access to the logs.

We also make sure that the Nginx is not running in daemon mode.

Please go over the config files to see exactly what we are doing.

We'll then copy them into the image during the build.

We then add the copy to our docker file.

```dockerfile
ADD ./files/nginx_config /site/nginx/config
```

Next, we want to install the composer.

```dockerfile
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php composer-setup.php --install-dir=/bin --filename=composer && \
    php -r "unlink('composer-setup.php');"
```

To allow for some simpler debugging, we're going to add ssh, allowing tools like Tinkerwell to connect.

```dockerfile
# Add openssh
RUN apt-get update && \
    apt-get -qy dist-upgrade && \
    apt-get install -qy \
      openssh-server \
      && \
    ssh-keygen -A && \
    mkdir -p /run/sshd && \
    apt-get -y autoremove && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/tmp/* && \
    rm -rf /tmp/*
```

Next we want to have the ability to become the www-data user. So we edit the ```/etc/passwd```.

```dockerfile
## Allow log in as user
RUN sed -i.bak -E \
      -s 's#/var/www:/usr/sbin/nologin#/var/www:/bin/bash#' \
      /etc/passwd
```

While doing dev or debugging it would be nice to have tab completion for artisan and composer.

We also want to easily access the binary files in composer.

Finally, we improve some the history settings.

```dockerfile
## Add tab completion
ADD ./files/bash/artisan-bash-prompt /etc/bash_completion.d/artisan-bash-prompt
ADD ./files/bash/composer-bash-prompt /etc/bash_completion.d/composer-bash-prompt

# Set up bash variables
RUN echo 'PATH="/usr/bin:/var/www/site/vendor/bin:/var/www/site/vendor/bin:/site/.composer/vendor/bin:${PATH}"' >> /var/www/.bashrc && \
    echo 'PATH="/usr/bin:/var/www/site/vendor/bin:/var/www/site/vendor/bin:/site/.composer/vendor/bin:${PATH}"' >> /root/.bashrc && \
    echo 'shopt -s histappend' >> /var/www/.bashrc && \
    echo 'shopt -s histappend' >> /root/.bashrc && \
    echo 'PROMPT_COMMAND="history -a;$PROMPT_COMMAND"' >> /var/www/.bashrc && \
    echo 'PROMPT_COMMAND="history -a;$PROMPT_COMMAND"' >> /root/.bashrc && \
    echo 'cd /var/www/site' >> /var/www/.bashrc && \
    echo 'cd /var/www/site' >> /root/.bashrc && \
    touch /root/.bash_profile /var/www/.bash_profile && \
    chown root: /etc/bash_completion.d/artisan-bash-prompt /etc/bash_completion.d/composer-bash-prompt && \
    chmod u+rw /etc/bash_completion.d/artisan-bash-prompt /etc/bash_completion.d/composer-bash-prompt && \
    chmod go+r /etc/bash_completion.d/artisan-bash-prompt /etc/bash_completion.d/composer-bash-prompt && \
    mkdir -p /var/www/site/tmp
```

Next we make sure that the files have the correct ownership.

```dockerfile
## Make sure directories and stdout and stderro have correct rights
RUN chmod -R a+w /dev/stdout && \
    chmod -R a+w /dev/stderr && \
    chmod -R a+w /dev/stdin && \
    usermod -a -G tty syslog && \
    usermod -a -G tty  www-data && \
    find /var/www -not -user www-data -execdir chown "www-data" {} \+
```

We now add logrotate configs for laravel to stop the log file getting to big.

We also add a scrip that will pass the env variables to other scripts.

```dockerfile
ADD ./files/logrotate.d/ /etc/logrotate.d/
ADD ./files/run_with_env.sh /bin/run_with_env.sh
```

To make the resulting image file more flexible we use environmental variables to change some settings in
the ```start.sh``` script.
(I'll cover the  ```start.sh``` once we've covered everything in the Dockerfile)

We set the default values for these next.

```dockerfile
ENV CRONTAB_ACTIVE="FALSE" \
    ENABLE_DEBUG="FALSE" \
    INITIALISE_FILE="/var/www/initialise.sh" \
    GEN_LV_ENV="FALSE" \
    LV_DO_CACHING="FALSE" \
    ENABLE_HORIZON="FALSE" \
    ENABLE_SIMPLE_QUEUE="FALSE" \
    SIMPLE_WORKER_NUM="5" \
    ENABLE_SSH="FALSE"

ENV PHP_TIMEZONE="UTC" \
    PHP_UPLOAD_MAX_FILESIZE="128M" \
    PHP_POST_MAX_SIZE="128M" \
    PHP_MEMORY_LIMIT="1G" \
    PHP_MAX_EXECUTION_TIME="60" \
    PHP_MAX_INPUT_TIME="60" \
    PHP_DEFAULT_SOCKET_TIMEOUT="60" \
    PHP_OPCACHE_MEMORY_CONSUMPTION="128" \
    PHP_OPCACHE_INTERNED_STRINGS_BUFFER="16" \
    PHP_OPCACHE_MAX_ACCELERATED_FILES="16229" \
    PHP_OPCACHE_REVALIDATE_PATH="1" \
    PHP_OPCACHE_ENABLE_FILE_OVERRIDE="0" \
    PHP_OPCACHE_VALIDATE_TIMESTAMPS="0" \
    PHP_OPCACHE_REVALIDATE_FREQ="1"

ENV PHP_OPCACHE_PRELOAD_FILE="" \
    COMPOSER_PROCESS_TIMEOUT=2000
```

The last bit of the docker file copies over the ```start.sh```, a template for supervisord and the health test script.

We then also set up the health test and set the start script to be the default thing run.

```dockerfile
WORKDIR /var/www/site

ADD ./files/healthCheck.sh /healthCheck.sh

RUN chown www-data: /healthCheck.sh && \
    chmod a+x /healthCheck.sh

HEALTHCHECK \
  --interval=30s \
  --timeout=30s \
  --start-period=15s \
  --retries=10 \
  CMD /healthCheck.sh

CMD ["/start.sh"]
```

That covers everything in the Docker file.

Let's just go over what
the [```./infra/docker/stage3-docker-ubuntu-php-lv/files/start.sh```](./infra/docker/stage3-docker-ubuntu-php-lv/files/start.sh)
does. This file gets run every time we start the image.

First we make sure that certain directories we need exist.

```shell
mkdir -p /var/www/site
mkdir -p /var/log/supervisor
mkdir -p /run/php
```

Next we set up some default environmental variables. You'll see these are a repeat of the ones in our Dockerfile.

You'll also see that if they are set in the enviroment that setting will take preference. This allows us to change them
by passing environmental variables during a docker run.

```shell
## All the following setting can be overwritten by passing environmental variables on the docker run
export PHP_VERSION=${PHP_VERSION:-7.4}

export CRONTAB_ACTIVE=${CRONTAB_ACTIVE:-FALSE}
export ENABLE_DEBUG=${ENABLE_DEBUG:-FALSE}

export INITIALISE_FILE=${INITIALISE_FILE:-'/var/www'}

export GEN_LV_ENV=${GEN_LV_ENV:-FALSE}
export LV_DO_CACHING=${LV_DO_CACHING:-FALSE}

export ENABLE_HORIZON=${ENABLE_HORIZON:-FALSE}
export ENABLE_SIMPLE_QUEUE=${ENABLE_SIMPLE_QUEUE:-FALSE}
export SIMPLE_WORKER_NUM=${SIMPLE_WORKER_NUM:-5}

export ENABLE_SSH=${ENABLE_SSH:-FALSE}

export PHP_TIMEZONE=${PHP_TIMEZONE:-"UTC"}
export PHP_UPLOAD_MAX_FILESIZE=${PHP_UPLOAD_MAX_FILESIZE:-"128M"}
export PHP_POST_MAX_SIZE=${PHP_POST_MAX_SIZE:-"128M"}
export PHP_MEMORY_LIMIT=${PHP_MEMORY_LIMIT:-"1G"}
export PHP_MAX_EXECUTION_TIME=${PHP_MAX_EXECUTION_TIME:-"60"}
export PHP_MAX_INPUT_TIME=${PHP_MAX_INPUT_TIME:-"60"}
export PHP_DEFAULT_SOCKET_TIMEOUT=${PHP_DEFAULT_SOCKET_TIMEOUT:-"60"}
export PHP_OPCACHE_MEMORY_CONSUMPTION=${PHP_OPCACHE_MEMORY_CONSUMPTION:-"128"}
export PHP_OPCACHE_INTERNED_STRINGS_BUFFER=${PHP_OPCACHE_INTERNED_STRINGS_BUFFER:-"16"}
export PHP_OPCACHE_MAX_ACCELERATED_FILES=${PHP_OPCACHE_MAX_ACCELERATED_FILES:-"16229"}
export PHP_OPCACHE_REVALIDATE_PATH=${PHP_OPCACHE_REVALIDATE_PATH:-"1"}
export PHP_OPCACHE_ENABLE_FILE_OVERRIDE=${PHP_OPCACHE_ENABLE_FILE_OVERRIDE:-"0"}
export PHP_OPCACHE_VALIDATE_TIMESTAMPS=${PHP_OPCACHE_VALIDATE_TIMESTAMPS:-"0"}
export PHP_OPCACHE_REVALIDATE_FREQ=${PHP_OPCACHE_REVALIDATE_FREQ:-"1"}
export PHP_OPCACHE_PRELOAD_FILE=${PHP_OPCACHE_PRELOAD_FILE:-""}

export COMPOSER_PROCESS_TIMEOUT=${COMPOSER_PROCESS_TIMEOUT:-2000}
```

As we've done previously we do some tuning of the php.ini using the environmental variables above.

```shell
sed -i \
  -e "s@date.timezone =.*@date.timezone = ${PHP_TIMEZONE}@" \
  -e "s/upload_max_filesize = .*/upload_max_filesize = ${PHP_UPLOAD_MAX_FILESIZE}/" \
  -e "s/post_max_size = .*/post_max_size = ${PHP_POST_MAX_SIZE}/"  \
  -e "s/memory_limit = .*/memory_limit = ${PHP_MEMORY_LIMIT}/" \
  -e "s/max_execution_time = .*/max_execution_time = ${PHP_MAX_EXECUTION_TIME}/" \
  -e "s/max_input_time = .*/max_input_time = ${PHP_MAX_INPUT_TIME}/" \
  -e "s/default_socket_timeout = .*/default_socket_timeout = ${PHP_DEFAULT_SOCKET_TIMEOUT}/" \
  -e "s/opcache.memory_consumption=.*/opcache.memory_consumption=${PHP_OPCACHE_MEMORY_CONSUMPTION}/" \
  -e "s/opcache.interned_strings_buffer=.*/opcache.interned_strings_buffer=${PHP_OPCACHE_INTERNED_STRINGS_BUFFER}/" \
  -e "s/.*opcache.max_accelerated_files=.*/opcache.max_accelerated_files=${PHP_OPCACHE_MAX_ACCELERATED_FILES}/" \
  -e "s/opcache.revalidate_path=.*/opcache.revalidate_path=${PHP_OPCACHE_REVALIDATE_PATH}/" \
  -e "s/opcache.enable_file_override=.*/opcache.enable_file_override=${PHP_OPCACHE_ENABLE_FILE_OVERRIDE}/" \
  -e "s/opcache.validate_timestamps=.*/opcache.validate_timestamps=${PHP_OPCACHE_VALIDATE_TIMESTAMPS}/" \
  -e "s/opcache.revalidate_freq=.*/opcache.revalidate_freq=${PHP_OPCACHE_REVALIDATE_FREQ}/" \
  /etc/php/"${PHP_VERSION}"/cli/php.ini \
  /etc/php/"${PHP_VERSION}"/fpm/php.ini
```

Next if you would like to do some opcache preloading you set a file to do this.

https://stitcher.io/blog/preloading-in-php-74

```shell
if [[ "${PHP_OPCACHE_PRELOAD_FILE}" != "" ]]; then
  sed -i \
    -e "s#;opcache.preload=.*#opcache.preload=${PHP_OPCACHE_PRELOAD_FILE}#" \
    -e "s#;opcache.preload_user=.*#opcache.preload_user=www-data#" \
    /etc/php/"${PHP_VERSION}"/fpm/php.ini
fi
```

Next we set up supervisor tuning what should run, and the quantity that should run.

As part of this you can choose to use Horizon or the simple queue worker.

I would recommend rather using horizon as it does give better reporting.

```shell
cp /supervisord_base.conf /supervisord.conf

if [[ "${ENABLE_HORIZON}" = "TRUE" ]]; then
  sed -E -i -e 's/^numprocs=ENABLE_HORIZON/numprocs=1/' /supervisord.conf
  SIMPLE_WORKER_NUM='0'
  ENABLE_SIMPLE_QUEUE='FALSE'
else
  sed -E -i -e 's/^numprocs=ENABLE_HORIZON/numprocs=0/' /supervisord.conf
fi

sed -E -i -e 's/^numprocs=WORKER_NUM/numprocs='"${WORKERS}"'/' /supervisord.conf

if [[ "${ENABLE_HORIZON}" != "TRUE" && "${ENABLE_SIMPLE_QUEUE}" = "TRUE" ]]; then
  sed -E -i -e 's/SIMPLE_WORKER_NUM/'"${SIMPLE_WORKER_NUM}"'/' /supervisord.conf
else
  sed -E -i -e 's/SIMPLE_WORKER_NUM/0/' /supervisord.conf
fi

if [[ "${ENABLE_SSH}" = "TRUE" ]]; then
  sed -E -i -e 's/ENABLE_SSH/1/' /supervisord.conf
else
  sed -E -i -e 's/ENABLE_SSH/0/' /supervisord.conf
fi

sed -E -i -e "s/PHP_VERSION/${PHP_VERSION}/g" /supervisord.conf
```

If you enable the ssh server we also allow you to add your ssh key via an environmental variable.

```shell
mkdir -p /root/.ssh/
chmod 700 /root/.ssh
ssh-keyscan github.com >> /root/.ssh/known_hosts
chmod 600 /root/.ssh/
touch /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

if [[ ! -z "${SSH_AUTHORIZED_KEYS}" ]];then
  echo "${SSH_AUTHORIZED_KEYS}" > /root/.ssh/authorized_keys
fi

chmod 600 /root/.ssh/authorized_keys
```

Next we set up the crontab.

By default, you'll se we have logrotate and a chown on start just in case.

We then have a variable, so you can decide if you want to enable Laravel's task scheduling.

https://laravel.com/docs/master/scheduling

```shell
cat > ${TEMP_CRON_FILE} <<- EndOfMessage
# m h  dom mon dow   command
0 * * * * /usr/sbin/logrotate -vf /etc/logrotate.d/*.auto 2>&1 | /dev/stdout

#rename on start
@reboot find /var/www -not -user www-data -execdir chown "www-data:" {} \+ | /dev/stdout

EndOfMessage

if [[ "${CRONTAB_ACTIVE}" = "TRUE" ]]; then
 cat >> ${TEMP_CRON_FILE} <<- EndOfMessage
* * * * * su www-data -c '/usr/bin/php /var/www/site/artisan schedule:run' 2>&1 >> /var/log/cron.log
EndOfMessage
fi

cat ${TEMP_CRON_FILE} | crontab -

rm ${TEMP_CRON_FILE}
```

Next is where can choose to enable xdebug.

```shell
if [[ "${ENABLE_DEBUG}" = "TRUE" ]]; then
  phpenmod -v "${PHP_VERSION}" xdebug
fi
```

By default, you can set the environmental variables for laravel directly.

Or if you would like to generate a ```.env``` file you can pass them prefixed with ```LVENV_``` and set ```GEN_LV_ENV```
to ```TRUE```.

The main advantage is it makes it simpler to see what the settings are by looking at the ```.env``` file.

```shell
if [[ "${GEN_LV_ENV}" = "TRUE" ]]; then
  env | grep 'LVENV_' | sort | sed -E -e 's/"/\\"/g' -e 's#LVENV_(.*)=#\1=#' -e 's#=(.+)#="\1"#' > /var/www/site/.env
fi
```

Next we override composers timeout. This is need if you are far from the composer servers. e.g. in Africa.

```shell
composer config --global process-timeout "${COMPOSER_PROCESS_TIMEOUT}"
```

Next we make sure the ```stdout``` add ```stdin``` are accessible.

```shell
# Try to fix rsyslogd: file '/dev/stdout': open error: Permission denied
chmod -R a+w /dev/stdout
chmod -R a+w /dev/stderr
chmod -R a+w /dev/stdin
```

We allow you to pass your own initialise file. This let you create a script that will do what ever setup you want before the server is up.

It generally will have things like composer install.

```shell
if [[ -e "${INITIALISE_FILE}" ]]; then
  chown www-data: "${INITIALISE_FILE}"
  chmod u+x "${INITIALISE_FILE}"
  mkdir /root/.composer /var/www/.composer
  chmod a+r /root/.composer /var/www/.composer
  su www-data --preserve-environment -c "${INITIALISE_FILE}" >> /var/log/initialise.log
fi
```

Finally, we do a quick logrotate just in case and start supervisor.

```shell
## Rotate logs at start just in case
/usr/sbin/logrotate -vf /etc/logrotate.d/*.auto &

/usr/bin/supervisord -n -c /supervisord.conf
```

### Simple local dev enviroment
Ok in this step we are going to set up a local dev enviroment using the php image we created above.

We'll also spin up a Redis and MySQL. Though for those we'll use the default images on [docker hub](https://hub.docker.com/).

I'm going to first show you how to do this via the command line.

I'll then give you docker-compose files to do this. 

The compose files are slightly easier to ready for people who are not used to command line.

#### Docker compose

To make things a bit simpler to manage and read I'll be using docker-compose files to set things up.

Let's first add the database.

We'll be using the default [PostgreSQL docker hub image](https://hub.docker.com/_/postgres), and we'll be using tag 13.

We are specifying a specific tag to prevent things breaking if the default version for Postgres increases. 

```yaml
version: '3.9'
services:
  pgmaster:
    image: postgres:13
    hostname: pgmaster.server
    restart: always
    environment:
      - "POSTGRES_DB=db_example"
      - "POSTGRES_USER=user_example"
      - "POSTGRES_PASSWORD=password_example"
    ports:
      - "5432:5432"
    volumes:
      - "db_pgmaster_vol:/var/lib/postgresql/data"
volumes:
  db_pgmaster_vol: {}
```

Next we want to add our

```shell
git clone https://github.com/thedevdojo/wave ./wave
```

```shell
docker-compose --project-name example up -d
```

```shell
docker-compose --project-name example down --remove-orphan
```

