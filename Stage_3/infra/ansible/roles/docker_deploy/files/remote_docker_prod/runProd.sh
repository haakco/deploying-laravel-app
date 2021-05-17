#!/usr/bin/env bash
export DOMAIN_NAME=example.com
export TRAEFIK_EMAIL=cert@example.com
export DB_NAME=db_example
export DB_USER=user_example
export DB_PASS=password_example
export APP_KEY=base64:8dQ7xw/kM9EYMV4cUkzKgET8jF4P0M0TOmmqN05RN2w=
export JWT_SECRET=Jrsweag3Mf0srOqDizRkhjWm5CEFcrBy

export TRUSTED_PROXIES='10.0.0.0/8,172.16.0.0./12,192.168.0.0/16'

export TRAEFIK_BASIC_USER="traefik"
export TRAEFIK_BASIC_PASSWORD_RAW='aitada1eeM6oomie1oog'
TRAEFIK_BASIC_PASSWORD_ENCODED=$(docker run --rm -ti xmartlabs/htpasswd "${TRAEFIK_BASIC_USER}" "${TRAEFIK_BASIC_PASSWORD_RAW}" | sed -E -e 's#.+\:(.+)#\1#' | xargs)
export TRAEFIK_BASIC_PASSWORD_ENCODED

cd /root/remote_docker_prod/ || exit
/usr/local/bin/docker-compose --project-name prod_example up -d
