#!/usr/bin/env bash
export PHP_VERSION="${PHP_VERSION:-7.4}"
export BASE_UBUNTU_VERSION="${BASE_UBUNTU_VERSION:-ubuntu:20.04}"
IMAGE_NAME_DEFAULT="haakco/stage3-${BASE_UBUNTU_VERSION}-php${PHP_VERSION}-lv-docker"
IMAGE_NAME_DEFAULT="${IMAGE_NAME_DEFAULT//:/-}"
export IMAGE_NAME="${IMAGE_NAME:-${IMAGE_NAME_DEFAULT}}"

echo "Building From: ${BASE_UBUNTU_VERSION}"
echo "Building PHP: ${PHP_VERSION}"
echo "Tagged as : ${IMAGE_NAME}"
echo ""
echo ""

CMD='docker build --rm --build-arg BASE_UBUNTU_VERSION='"${BASE_UBUNTU_VERSION}"' --build-arg PHP_VERSION='"${PHP_VERSION}"' -t '"${IMAGE_NAME}"' .'

echo "Build commmand: ${CMD}"
echo ""
${CMD}
