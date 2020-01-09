#!/bin/sh

echo
echo "CLI_ARGS: \"${@}\""
if [[ ${#} != 0 ]]; then
  exec $@
else
  mkdir -p /repo/consul_kv_backup ; cd /repo/consul_kv_backup ; /usr/bin/consul_kv_backup --config-file /etc/consul_kv_backup/config.json
  echo
fi
