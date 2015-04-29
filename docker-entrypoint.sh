#!/bin/bash
set -eo pipefail

if [ -n "$FLEETCTL_ENDPOINT" -a -e '/usr/bin/confd' ]; then
    export FLEETCTL_ENDPOINT=$FLEETCTL_ENDPOINT
    echo "[haproxy] booting container. ETCD: $FLEETCTL_ENDPOINT"

    # Loop until confd has updated the haproxy config
    until confd -onetime -node $FLEETCTL_ENDPOINT -config-file /etc/confd/conf.d/haproxy.cfg.toml; do
      echo "[haproxy] waiting for confd to refresh haproxy.conf"
      sleep 5
    done
    
    # Run confd in the background to watch the upstream servers
    confd -interval 10 -node $FLEETCTL_ENDPOINT -config-file /etc/confd/conf.d/haproxy.cfg.toml &
    echo "[haproxy] confd is listening for changes on etcd..."
fi
    
# Start haproxy
echo "[haproxy] starting haproxy service..."
service haproxy start
