#!/bin/bash -eux

echo "==> Recording box generation date"
date > /etc/box_build_date

echo "==> Customizing message of the day"
MOTD_FILE=/etc/motd
BANNER_WIDTH=64
UBUNTU_VERSION=$(lsb_release -r | sed -E -e 's/[^0-9]+([0-9.]+)/\1/')
PLATFORM_RELEASE=$(lsb_release -sd)
PLATFORM_MSG=$(printf '%s' "$PLATFORM_RELEASE")
BUILT_MSG=$(printf 'built %s' $(date +%Y-%m-%d))
printf '%0.1s' "-"{1..64} > ${MOTD_FILE}
printf '\n' >> ${MOTD_FILE}
printf '%2s%-30s%30s\n' " " "${PLATFORM_MSG}" "${BUILT_MSG}" >> ${MOTD_FILE}
printf '%0.1s' "-"{1..64} >> ${MOTD_FILE}
printf '\n' >> ${MOTD_FILE}
echo "PHP SA Ubuntu ${UBUNTU_VERSION} Docker" >> ${MOTD_FILE}
printf '\n' >> ${MOTD_FILE}
exit 0
