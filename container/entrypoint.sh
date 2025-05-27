#!/bin/bash

# only create the priv_validator_state.json if it doesn't exist and the command is start
if [[ $1 == "start" && ! -f ${ZKCLOUD_HOME}/data/priv_validator_state.json ]]
then
    mkdir -p ${ZKCLOUD_HOME}/data
    cat <<EOF > ${ZKCLOUD_HOME}/data/priv_validator_state.json
{
  "height": "0",
  "round": 0,
  "step": 0
}
EOF
fi

# Check if the `upgrade-info.json` file should be populated.
if [[ -n "$UPGRADE_VERSION" && -n "$UPGRADE_HEIGHT" ]]; then
  echo "Upgrade version env variables found:"
  echo "  UPGRADE_VERSION=$UPGRADE_VERSION"
  echo "  UPGRADE_HEIGHT=$UPGRADE_HEIGHT"

  # Check if upgrade-info.json exists
  if [[ ! -f upgrade-info.json ]]; then
    echo "Creating upgrade-info.json."
    echo "{\"name\":\"$UPGRADE_VERSION\",\"time\":\"0001-01-01T00:00:00Z\",\"height\":$UPGRADE_HEIGHT}" > "${ZKCLOUD_HOME}/data/upgrade-info.json"
    echo "upgrade-info.json created."
  else
    echo "upgrade-info.json already exists. No action taken."
  fi
else
  echo "UPGRADE_VERSION and/or UPGRADE_HEIGHT are not set or empty. Continuing with cosmovisor default behavior."
fi


cp -rvf /app/cosmovisor ${HOME}/.zkcloud/cosmovisor

exec /bin/cosmovisor run "$@"
