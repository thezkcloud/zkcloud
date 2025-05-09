#!/bin/bash

cp -rvf /app/cosmovisor ${HOME}/.zkcloud/cosmovisor

exec /bin/cosmovisor run "$@"
