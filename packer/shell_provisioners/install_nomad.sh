#!/bin/bash

export NOMAD_VERSION="${nomad_version}"
export NOMAD_ZIPFILE="nomad_"$NOMAD_VERSION"_linux_amd64.zip"
export NOMAD_URL="https://releases.hashicorp.com/nomad/"$NOMAD_VERSION"/"$NOMAD_ZIPFILE

apt update

apt install -y unzip

wget -p /tmp $NOMAD_URL
unzip -d /tmp $NOMAD_ZIPFILE

sudo chown root:root /tmp/nomad

mv nomad /usr/local/bin

mv /tmp/nomad /usr/local/bin/

useradd --system --home /etc/nomad.d --shell /bin/false nomad
mkdir --parents /opt/nomad
chown --recursive nomad:nomad /opt/nomad