#!/bin/bash
set -eo pipefail

# WTF they do this... 
sed -i /etc/default/haproxy -e 's/ENABLED=0/ENABLED=1/g'

if [ -n "$FLEETCTL_ENDPOINT" -a -e '/usr/bin/confd' ]; then
    export FLEETCTL_ENDPOINT=$FLEETCTL_ENDPOINT
    echo "[haproxy] booting container. ETCD: $FLEETCTL_ENDPOINT"

    # Loop until confd has updated the haproxy config
    until confd -onetime -node $FLEETCTL_ENDPOINT -config-file /etc/confd/conf.d/haproxy.cfg.toml; do
      echo "[haproxy] waiting for confd to refresh haproxy.conf"
      sleep 5
    done
    
    # Start haproxy
    echo "[haproxy] starting haproxy service..."
    service haproxy start
    # Run confd in the background to watch the upstream servers
    echo "[haproxy] confd is listening for changes on etcd..."
    exec confd -interval 10 -node $FLEETCTL_ENDPOINT -config-file /etc/confd/conf.d/haproxy.cfg.toml
fi
    
