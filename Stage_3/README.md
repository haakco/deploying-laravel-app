# Stage 3: The different stages to learning how to deploy a Laravel App

## Intro

For this stage, we'll move to create docker containers. Having versioned containers makes it simpler, role forward and backwards.
It also gives us a way to test locally on a system that is close to production.

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

The image will have all the libraries and we need, and it will have NGINX built in to make our lives easier.

This image will hold everything required except the Laravel code.

We'll then use this image to create our final image for deployment.

We split the images to save us time rebuilding the whole image every time we do a code change.

The final docker file and anything needed to build it can be found at [```./infra/docker/ubuntu-php-lv-docker/```](infra/docker/stage3-docker-ubuntu-php-lv/)

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
    TZ="Africa/Johannesburg" \
    PHP_VERSION="$PHP_VERSION"

RUN echo "PHP_VERSION=${PHP_VERSION}" && \
    echo "UBUNTU_VERSION=${BASE_UBUNTU_VERSION}" && \
    echo ""
```

After this, we follow either the steps we have from any of the earlier stages.

I'm mainly following the installation script we used in Stage_0. (Remember how I said you'd be re-using this)

For refrence the install script is here [```../Stage_0/setupCommands.sh```](../Stage_0/setupCommands.sh)

The one exception is we don't have to generate the SSL certificate, as we'll do that with a proxy that we'll run
in front of the server.

We'll also set some flags to speed up the apt install.

So let's first make sure the Ubuntu is entirely up to date.

We also install some base required packages.

You'll see after each run command, we do a cleanup to keep each layer as small as possible.

```dockerfile
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
    echo apt-fast apt-fast/maxdownloads string 10 | debconf-set-selections && \
    echo apt-fast apt-fast/dlflag boolean true | debconf-set-selections && \
    echo apt-fast apt-fast/aptmanager string apt-get | debconf-set-selections && \
    echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup && \
    echo "Acquire::http {No-Cache=True;};" > /etc/apt/apt.conf.d/no-cache
    
RUN apt update && \
    apt -y  \
        dist-upgrade \
        && \
    apt-get install -qy \
        software-properties-common \
        && \
    apt-get -y autoremove && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/tmp/* && \
    rm -rf /tmp/*
```

Next, we want to install PHP.

```dockerfile
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
      php${PHP_VERSION}-xml \
      php${PHP_VERSION}-zip \
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

Now let us install Nginx.

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

We'll need a config for the server.

For this, we'll create a files directory and add the config files for Nginx in a subdirectory.

One thing to note is that we send the Nginx logs to stdout and stderr, allowing more straightforward access to the logs.

We'll then copy them into the image during the build.

The config files can be found here.

[```./infra/docker/ubuntu-php-lv-docker/files/nginx_config```](infra/docker/stage3-docker-ubuntu-php-lv/files/nginx_config)

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
RUN apt-get -o update && \
    apt-get -o -qy dist-upgrade && \
    apt-get -o install -qy \
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



