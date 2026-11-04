#!/bin/bash
set -e
PW=$(jq -r '.root_password // empty' /data/options.json)
[ -n "$PW" ] || { echo "root_password not set"; exit 1; }
mkdir -p /data/mongodb
chown -R mongodb:mongodb /data/mongodb
export MONGO_INITDB_ROOT_USERNAME=nsroot MONGO_INITDB_ROOT_PASSWORD="$PW"
unset PW
exec docker-entrypoint.sh mongod --bind_ip_all --dbpath /data/mongodb --wiredTigerCacheSizeGB 0.25 --quiet
