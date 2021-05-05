#!/usr/bin/env bash
env > /var/www/initialise.env
export HOME=/var/www

export LV_DO_CACHING=${LV_DO_CACHING:-"FALSE"}
export CRONTAB_ACTIVE=${CRONTAB_ACTIVE:-"FALSE"}
export LVENV_APP_ENV=${LVENV_APP_ENV:-"dev"}

cd /var/www/site/ || exit

composer config --global process-timeout "${COMPOSER_PROCESS_TIMEOUT}"

if [[ "${LVENV_APP_ENV}" = "production" ]]; then
  composer install --no-ansi --no-suggest --prefer-dist --no-progress --no-interaction \
    --no-dev --classmap-authoritative
else
  composer install --no-ansi --no-suggest --prefer-dist --no-progress --no-interaction
fi

if [[ "${AUTO_DO_MIGRATIONS}" = "TRUE" ]]; then
  echo "AUTO_DO_MIGRATIONS ENABLED Auto running migrations"
  ./artisan migrate --step
fi

if [[ "${CRONTAB_ACTIVE}" = "TRUE" ]]; then
  echo "CRONTAB_ACTIVE ENABLED Clearing schedule cache"
  ./artisan schedule:cache:clear
fi

composer clear

if [[ "${LV_DO_CACHING}" = "TRUE" ]]; then
  echo "LV_DO_CACHING ENABLED"
  composer cache
fi

