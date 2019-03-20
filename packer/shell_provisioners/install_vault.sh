#!/bin/bash

export VAULT_VERSION="${vault_version}"
export VAULT_ZIPFILE="vault_"$VAULT_VERSION"_linux_amd64.zip"
export VAULT_DOWNLOAD_PATH="/tmp/"
export VAULT_URL="https://releases.hashicorp.com/vault/"$VAULT_VERSION"/"$VAULT_ZIPFILE

export VAULT_BASE_PATH="/opt/consul"
export VAULT_BIN_PATH=$VAULT_BASE_PATH"/bin"
export VAULT_CONFIG_PATH=$VAULT_BASE_PATH"/config"
export VAULT_DATA_PATH=$VAULT_BASE_PATH"/data"


mkdir --parents /opt/vault/config/
mkdir --parents /opt/vault/data/
mkdir --parents /opt/vault/bin/

wget -p /tmp "$VAULT_URL"
unzip -d /tmp "$VAULT_DOWNLOAD_PATH$VAULT_ZIPFILE"

mv /tmp/vault /opt/vault/bin/

useradd --system --home /opt/vault/config --shell /bin/false vault

chown --recursive vault:vault /opt/vault
