#!/bin/bash

export CONSUL_VERSION="${consul_version}"
export CONSUL_ZIPFILE="consul_"$CONSUL_VERSION"_linux_amd64.zip"
export CONSUL_DOWNLOAD_PATH="/tmp/"
export CONSUL_DOWNLOAD_URL="https://releases.hashicorp.com/consul/"$CONSUL_VERSION"/consul_"$CONSUL_VERSION"_linux_amd64.zip"

export CONSUL_USER="consul"
export CONSUL_GROUP="consul"

export CONSUL_BASE_PATH="/opt/consul"
export CONSUL_BIN_PATH=$CONSUL_BASE_PATH"/bin"
export CONSUL_CONFIG_PATH=$CONSUL_BASE_PATH"/config"
export CONSUL_DATA_PATH=$CONSUL_BASE_PATH"/data"

mkdir --parents $CONSUL_BIN_PATH
mkdir --parents $CONSUL_CONFIG_PATH
mkdir --parents $CONSUL_DATA_PATH

wget -P $CONSUL_DOWNLOAD_PATH $CONSUL_DOWNLOAD_URL

unzip -d $CONSUL_DOWNLOAD_PATH $CONSUL_DOWNLOAD_PATH$CONSUL_ZIPFILE

mv "$CONSUL_DOWNLOAD_PATH/consul" $CONSUL_BIN_PATH

useradd --system --home $CONSUL_CONFIG_PATH --shell /bin/false $consuluser

chown --recursive $CONSUL_USER:$CONSUL_GROUP $CONSUL_BASE_PATH
