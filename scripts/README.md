# How to deploy a multi-node testnet

## Generate the configuration files

```bash
podman volume create zkcloud-testnets
podman run --volume zkcloud-testnets:/home/zkcloud:Z --entrypoint /testnet-multi-node.sh ghcr.io/thezkcloudd/zkcloud:<tag> "$VALIDATORS_COUNT" "<public_ip1,public_ip2,public_ip3,public_ip4>"
```

Files will be generated into the folder `/var/lib/containers/storage/volumes/zkcloud-testnets/_data/.testnets`.

There will be one subfolder for each $VALIDATORS_COUNT. Copy the appropriate validator configuration to the remote hosts.

## Deploy the validator on a remote host

```bash
# Create a podman volume
podman volume create "$SERVICE_NAME-data"

# Deploy the appropriate configuration into the volume directory (default /var/lib/containers/storage/volumes/<service_name>-data/_data//)
mkdir -p /var/lib/containers/storage/volumes/$SERVICE_NAME-data/_data/.zkcloud
cp -r .testnets/validator<n>/* /var/lib/containers/storage/volumes/$SERVICE_NAME-data/_data/.zkcloud/
chown -R 10001 /var/lib/containers/storage/volumes/$SERVICE_NAME-data/_data/.zkcloud

# deploy the systemd service file
cp validator-service.service /etc/systemd/system/$SERVICE_NAME.service
systemctl daemon-reload
systemctl start $SERVICE_NAME
```
