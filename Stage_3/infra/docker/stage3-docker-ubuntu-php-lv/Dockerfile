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
        apt-transport-https \
        bash-completion bzip2 \
        ca-certificates cron curl \
        dos2unix dnsutils \
        git \
        inetutils-ping inetutils-tools \
        jq \
        logrotate \
        net-tools \
        mysql-client \
        openssl \
        postgresql-client procps psmisc \
        rsyslog \
        software-properties-common ssl-cert sudo supervisor \
        tar \
        unzip \
        vim \
        && \
    update-ca-certificates --fresh && \
    apt-get -y autoremove && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/tmp/* && \
    rm -rf /tmp/*

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

## Install nginx
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
    rm -rf /etc/nginx/sites-enabled/default && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/tmp/* && \
    rm -rf /tmp/*

ADD ./files/nginx_config /etc/nginx

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php composer-setup.php --install-dir=/bin --filename=composer && \
    php -r "unlink('composer-setup.php');"

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

## Allow log in as user
RUN sed -i.bak -E \
      -s 's#/var/www:/usr/sbin/nologin#/var/www:/bin/bash#' \
      /etc/passwd

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

ADD ./files/logrotate.d/ /etc/logrotate.d/
ADD ./files/run_with_env.sh /bin/run_with_env.sh

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

ADD ./files/initialise.sh /var/www/initialise.sh
ADD ./files/start.sh /start.sh
ADD ./files/supervisord_base.conf /supervisord_base.conf

RUN chown www-data: -R /var/www/initialise.sh /var/www && \
    chmod a+x /var/www/initialise.sh && \
    chmod a+x /start.sh

## Make sure directories and stdout and stderro have correct rights
RUN chmod -R a+w /dev/stdout && \
    chmod -R a+w /dev/stderr && \
    chmod -R a+w /dev/stdin && \
    usermod -a -G tty syslog && \
    usermod -a -G tty www-data && \
    find /var/www -not -user www-data -execdir chown "www-data" {} \+

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

EXPOSE 80/tcp
EXPOSE 9090/tcp

CMD ["/start.sh"]
