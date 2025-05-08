#!/bin/bash


NETWORK="${NETWORK:-testnet}"
RPC_ENDPOINT="${RPC_ENDPOINT:-https://grpc.${NETWORK}.zkcloud.com}"

echo "Running full node for ${NETWORK}"

# Function to fetch proposals with pagination
fetch_proposals() {
    next_key="$1"
    page_size=100

    # Make the request
    response=$(wget -qO- \
        --header="Content-Type: application/json" \
        "$RPC_ENDPOINT/cosmos/gov/v1/proposals?pagination.key=${next_key}&pagination.limit=${page_size}")

    echo "$response"
}

# Main function to fetch all proposals
all_proposals() {
    all_proposals="[]"
    next_key=""

    while true; do
        response=$(fetch_proposals "$next_key")

        # Extract proposals from current page and combine with previous proposals
        all_proposals=$(echo "$response" | jq -r --argjson prev "$all_proposals" '.proposals as $curr | $prev + $curr')

        # Get next key for pagination
        next_key=$(echo "$response" | jq -r '.pagination.next_key')

        # Break if no more pages
        if [ "$next_key" = "null" ] || [ -z "$next_key" ]; then
            break
        fi

        echo "Fetched page, next key: $next_key"
    done

    echo "$all_proposals"
}


# only create the priv_validator_state.json if it doesn't exist and the command is start
if [[ $1 == "start" && ! -f ${DAEMON_HOME}/data/priv_validator_state.json ]]
then
    mkdir -p ${DAEMON_HOME}/data
    cat <<EOF > ${DAEMON_HOME}/data/priv_validator_state.json
{
  "height": "0",
  "round": 0,
  "step": 0
}
EOF
fi

mkdir -p "${DAEMON_HOME}"
cp -r /app/cosmovisor "${DAEMON_HOME}"/

update_link() {
    new_version=$(all_proposals | jq -rc 'sort_by(.id).[-1] | select(.status == "PROPOSAL_STATUS_PASSED").messages[] | select(."@type" == "/cosmos.upgrade.v1beta1.MsgSoftwareUpgrade").plan.name')

    echo "New version: ${new_version}"

    if [ "${new_version}" != "" ]; then
        rm "${DAEMON_HOME}/cosmovisor/current"
        ln -s "${DAEMON_HOME}/cosmovisor/upgrades/${new_version}" "${DAEMON_HOME}/cosmovisor/current"
    fi
}

if [ -n "${EMBER_VERSION}" ]; then
    echo "Switching symlink to ember version: ${EMBER_VERSION}"
    rm "${DAEMON_HOME}/cosmovisor/current"
    ln -s "${DAEMON_HOME}/cosmovisor/upgrades/${EMBER_VERSION}" "${DAEMON_HOME}/cosmovisor/current"
else
    # Only update the link when we don't have an explicit version and if the rpc endpoint responds.
    curl -si "${RPC_ENDPOINT}" | head -1 | grep 200 > /dev/null && update_link
fi

echo "Starting zkcloudd under cosmovisor with command:"
echo "/bin/cosmovisor $@"
echo ""

exec /bin/cosmovisor run "$@"
