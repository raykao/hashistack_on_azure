#!/bin/bash

export VAULT_ZIPFILE="vault_"$VAULT_VERSION"_linux_amd64.zip"
export VAULT_URL="https://releases.hashicorp.com/vault/"$VAULT_VERSION"/"$VAULT_ZIPFILE

cd /tmp

wget -p /tmp $VAULT_URL
unzip -d /tmp $VAULT_ZIPFILE

sudo chown root:root /tmp/vault

mv vault /usr/local/bin

mv /tmp/vault /usr/local/bin/

useradd --system --home /etc/vault.d --shell /bin/false vault
mkdir --parents /opt/vault
chown --recursive vault:vault /opt/vault
