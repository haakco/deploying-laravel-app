#!/usr/bin/env bash
terraform init
terraform providers lock \
  -platform=linux_arm64 \
  -platform=linux_amd64 \
  -platform=darwin_amd64 \
  -platform=windows_amd64
terraform apply -refresh=true -parallelism=10