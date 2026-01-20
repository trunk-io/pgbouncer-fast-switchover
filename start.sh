#!/bin/bash -x
set -euo pipefail

PGB_DIR="/home/pgbouncer"
INI="${PGB_DIR}/pgbouncer.ini"
USERLIST="${PGB_DIR}/userlist.txt"

# iterate over env vars starting with DB_SECRET
# https://stackoverflow.com/a/25765360
while IFS='=' read -r name value ; do
  if [ -n "${value}" ]; then
    PGB_ADMIN_USERS=$(echo $value | jq ".username" | tr -d '"')","${PGB_ADMIN_USERS:-}
    PGB_ADMIN_PASSWORDS=$(echo $value | jq ".password" | tr -d '"')","${PGB_ADMIN_PASSWORDS:-}
    if [ -z "${PGB_DATABASES:-}" ]; then
      PGB_LISTEN_PORT=$(echo $value | jq ".port")
      PGB_DATABASES=$(echo "${value}" | jq -c '"host=" + .host + " port=" + (.port | tostring)' | tr -d '"')
    fi
  fi
done < <(env | grep ^DB_SECRET)

if [ -z "${PGB_ADMIN_USERS+x}" ]; then
  PGB_ADMIN_USERS="admin"
  PGB_ADMIN_PASSWORDS="pw"
fi

# Auto-generate conf if it doesn't exist
if [ ! -f ${INI} ]; then
  if [[ -z "${PGB_DATABASES:-}" ]]; then
    echo "Error: no databases specified in \$PGB_DATABASES"
    exit 1
  fi

cat <<- END > $INI
[databases]
    * = $PGB_DATABASES
[pgbouncer]
    listen_port = ${PGB_LISTEN_PORT:-5432}
    listen_addr = ${PGB_LISTEN_ADDR:-0.0.0.0}
    auth_type = md5
    default_pool_size = ${POOL_SIZE:-45}
    max_client_conn = ${MAX_CLIENT_CONN:-1000}
    log_connections = 1
    log_disconnections = 1
    log_pooler_errors = 1
    routing_rules_py_module_file = /home/pgbouncer/routing_rules.py
    log_stats = 1
    pool_mode = transaction
    auth_file = $USERLIST
    logfile = $PGB_DIR/pgbouncer.log
    pidfile = $PGB_DIR/pgbouncer.pid
    admin_users = ${PGB_ADMIN_USERS:-admin}
    server_tls_sslmode = verify-full
    server_tls_ca_file = ${SERVER_CERT_FILE:-/home/pgbouncer/server-certs/server.crt}
    client_tls_sslmode = require
    client_tls_key_file = ${CLIENT_KEY_FILE:-/home/pgbouncer/client-certs/tls.key}
    client_tls_cert_file = ${CLIENT_CERT_FILE:-/home/pgbouncer/client-certs/tls.crt}
END
  cat $INI
fi

# Auto-generate conf if it doesn't exist
if [ ! -f ${USERLIST} ]; then
  # convert comma-separated string variables to arrays.
  IFS=',' read -ra admin_array <<< "$PGB_ADMIN_USERS"
  IFS=',' read -ra password_array <<< "$PGB_ADMIN_PASSWORDS"

  # check every admin account has a corresponding password, and vice versa
  if (( ${#admin_array[@]} != ${#password_array[@]} )); then
      exit 1
  fi

  # Zip admin arrays together and write them to userlist.
  for (( i=0; i < ${#admin_array[*]}; ++i )); do
      echo "\"${admin_array[$i]}\" \"${password_array[$i]}\"" >> $USERLIST
  done
fi

chmod 0600 $INI
chmod 0600 $USERLIST
#/pub_metrics.sh &
#/adaptivepgbouncer.sh &
pgbouncer $INI ${VERBOSE:-}
