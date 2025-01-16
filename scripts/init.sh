#!/usr/bin/env bash

DAEMON_BIN=${DAEMON_BIN:=$(which zkcloudd 2>/dev/null)}
CHAIN_ID="zkcloud-1"
DENOM="uproof"

if [ -z "$DAEMON_BIN" ]; then 
    echo "DAEMON_BIN is not set. Make sure zkcloudd is installed and in your PATH"; 
    exit 1
fi

echo "Using $DAEMON_BIN"

# Setup home directory and configuration
DAEMON_HOME=$($DAEMON_BIN config home)
if [ -d "$DAEMON_HOME" ]; then 
    rm -rv $DAEMON_HOME
fi

# Set client configuration
$DAEMON_BIN config set client chain-id $CHAIN_ID
$DAEMON_BIN config set client keyring-backend test
$DAEMON_BIN config set client keyring-default-keyname validator
$DAEMON_BIN config set app api.enable true
$DAEMON_BIN config set app api.swagger true
$DAEMON_BIN config set app telemetry.prometheus-retention-time 600

# Initialize the chain
$DAEMON_BIN init zkcloud-node --chain-id $CHAIN_ID

# Modify genesis for faster block times and enable prometheus
sed -i'' -e 's/timeout_commit = "5s"/timeout_commit = "1s"/' "$DAEMON_HOME"/config/config.toml
sed -i'' -e 's/prometheus = false/prometheus = true/' "$DAEMON_HOME"/config/config.toml

# Create accounts
$DAEMON_BIN keys add validator --keyring-backend test
$DAEMON_BIN keys add alice --keyring-backend test
$DAEMON_BIN keys add bob --keyring-backend test

# Create random test accounts
aliases=""
for i in $(seq 5); do
    alias=$(dd if=/dev/urandom bs=16 count=24 2> /dev/null | base64 | head -c 32)
    $DAEMON_BIN keys add "$alias" --keyring-backend test
    aliases="$aliases $alias"
done
echo "Generated test accounts: $aliases"

# Modify genesis parameters
# Change staking and gov denom to uproof
sed -i'' -e 's/"stake"/"uproof"/g' "$DAEMON_HOME"/config/genesis.json

# Update governance parameters
jq '.app_state.gov.params.voting_period = "600s"' $DAEMON_HOME/config/genesis.json > temp.json && mv temp.json $DAEMON_HOME/config/genesis.json
jq '.app_state.gov.params.expedited_voting_period = "300s"' $DAEMON_HOME/config/genesis.json > temp.json && mv temp.json $DAEMON_HOME/config/genesis.json
jq '.app_state.mint.minter.inflation = "0.300000000000000000"' $DAEMON_HOME/config/genesis.json > temp.json && mv temp.json $DAEMON_HOME/config/genesis.json

# Add genesis accounts with initial balances
$DAEMON_BIN genesis add-genesis-account validator 5000000000000$DENOM --keyring-backend test
$DAEMON_BIN genesis add-genesis-account alice 1000000000000$DENOM --keyring-backend test
$DAEMON_BIN genesis add-genesis-account bob 1000000000000$DENOM --keyring-backend test

# Add balances for test accounts
for a in $aliases; do
    $DAEMON_BIN genesis add-genesis-account "$a" 100000000000$DENOM --keyring-backend test
done

# Create and collect gentx
$DAEMON_BIN genesis gentx validator 100000000000$DENOM \
    --chain-id $CHAIN_ID \
    --moniker "zkcloud-validator" \
    --commission-max-change-rate 0.01 \
    --commission-max-rate 0.2 \
    --commission-rate 0.1 \
    --min-self-delegation 1 \
    --keyring-backend test

$DAEMON_BIN genesis collect-gentxs
