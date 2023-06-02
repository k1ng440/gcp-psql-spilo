export NETWORK_INTERFACE=$(ip r l | grep "default via" | awk '{print $5}')
export SERVER_IP_ADDRESS=$(ip a l dev "$NETWORK_INTERFACE" | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
export INSTANCE=$(hostname | awk 'BEGIN {FS="-";} {print $NF}')
