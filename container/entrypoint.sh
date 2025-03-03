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

echo "Starting zkcloudd with command:"
echo "/bin/zkcloudd $@"
echo ""

exec /bin/zkcloudd $@