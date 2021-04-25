#!/usr/bin/env bash
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
  echo "Missing variable should follow the following example"
  echo "./createDb db_example user_example password_example"
  exit
fi

cd /var/lib/postgresql/ || exit

touch /root/db_created
sudo su postgres <<EOF
psql -c "CREATE USER $2 WITH PASSWORD '$3';"
createdb -O$2 -Eutf8 $1;
echo "Postgres database '$1' with user $2 created."
EOF
