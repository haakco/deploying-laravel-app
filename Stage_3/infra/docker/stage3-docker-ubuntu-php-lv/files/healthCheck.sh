#!/bin/bash
if [ $(/usr/bin/curl -LI http://localhost -o /dev/null -w '%{http_code}\n' -s) == "200" ]; then
  echo 0
else
  echo 1
fi
