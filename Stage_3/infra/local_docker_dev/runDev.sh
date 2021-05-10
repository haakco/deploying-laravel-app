#!/usr/bin/env bash
export TRAEFIK_EMAIL=cert@custd.com
export CLOUDFLARE_API_TOKEN=$CLOUDFLARE_API_TOKEN
export DOMAIN_NAME=dev.custd.com
export DB_NAME=db_example
export DB_USER=user_example
export DB_PASS=password_example
export APP_KEY=base64:8dQ7xw/kM9EYMV4cUkzKgET8jF4P0M0TOmmqN05RN2w=
export JWT_SECRET=Jrsweag3Mf0srOqDizRkhjWm5CEFcrBy
docker-compose --project-name example up -d
