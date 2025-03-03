#!/usr/bin/env bash

if [ $# -ne 2 ]; then
    echo "Error: Script requires exactly 2 arguments"
    echo "Usage: $0 <validator_count> <comma_separated_ips>"
    exit 1
fi

DAEMON_BIN=${DAEMON_BIN:=$(which zkcloudd 2>/dev/null)}
CHAIN_ID="zkcloud-1"
DENOM="uproof"

CONFIG_DIR="/home/zkcloud/.testnets"
VALIDATORS_COUNT="${1}"
IPS=(${2//,/ })

if [ $# -ne 2 ]; then
    echo "Error: Script requires exactly 2 arguments"
    echo "Usage: $0 <validator_count> <comma_separated_ips>"
    exit 1
fi

if [ ${#IPS[@]} -ne $VALIDATORS_COUNT ]; then
    echo "Error: Number of IPs (${#IPS[@]}) does not match validator count ($VALIDATORS_COUNT)"
    exit 1
fi

# Generate multi-node config directories & files
$DAEMON_BIN multi-node --v "${VALIDATORS_COUNT}" --node-dir-prefix validator --output-dir "${CONFIG_DIR}"


# Change denom to uproof
echo "Processing directory: ${CONFIG_DIR}"
find "${CONFIG_DIR}" -type f -name "genesis.json" -exec sed -i "s/stake/uproof/g" {} \;

# Replace persistent peers with public_ip:26656
for ((i=1; i<=VALIDATORS_COUNT; i++)); do
    port=$((26656 - (i-1)*3))
    ip="${IPS[$i-1]}"

    find "${CONFIG_DIR}" -type f -name "config.toml" -exec sed -i "s/localhost:$port/$ip:26656/g" {} \;
done

# Override p2p listen address
find "${CONFIG_DIR}" -type f -name "config.toml" -exec sed -i '/# Address to listen for incoming connections/{n;s/laddr = "tcp:\/\/0\.0\.0\.0:[0-9]\+"/laddr = "tcp:\/\/0.0.0.0:26656"/}' {} \;
