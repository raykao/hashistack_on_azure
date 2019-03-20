#!/bin/bash

export CONSUL_VERSION="${consul_version}"
export CONSUL_ZIPFILE="consul_"$CONSUL_VERSION"_linux_amd64.zip"
export CONSUL_DOWNLOAD_PATH="/tmp/consul_"$CONSUL_VERSION"_linux_amd64.zip"
export CONSUL_DOWNLOAD_URL="https://releases.hashicorp.com/consul/"$CONSUL_VERSION"/consul_"$CONSUL_VERSION"_linux_amd64.zip"

apt update

apt install -y unzip

wget -P /tmp "$CONSUL_DOWNLOAD_URL"

unzip -d /tmp "$CONSUL_DOWNLOAD_PATH"

chown root:root /tmp/consul

mv /tmp/consul /usr/local/bin/

consul -autocomplete-install
complete -C /usr/local/bin/consul consul

useradd --system --home /opt/consul/config --shell /bin/false consul
mkdir --parents /opt/consul
chown --recursive consul:consul /opt/consul