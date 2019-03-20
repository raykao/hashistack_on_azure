#!/bin/bash

export NOMAD_VERSION="${nomad_version}"
export NOMAD_ZIPFILE="nomad_"$NOMAD_VERSION"_linux_amd64.zip"
export NOMAD_URL="https://releases.hashicorp.com/nomad/"$NOMAD_VERSION"/"$NOMAD_ZIPFILE

mkdir --parents /opt/consul/bin
mkdir --parents /opt/consul/config
mkdir --parents /opt/consul/data

wget -p /tmp $NOMAD_URL
unzip -d /tmp $NOMAD_ZIPFILE

mv /tmp/nomad /opt/nomad/bin/

useradd --system --home /opt/nomad/config --shell /bin/false nomad

chown --recursive nomad:nomad /opt/nomad