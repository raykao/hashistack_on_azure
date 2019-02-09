#!/bin/bash

export NOMAD_ZIPFILE="nomad_"$NOMAD_VERSION"_linux_amd64.zip"
export NOMAD_URL="https://releases.hashicorp.com/nomad/"$NOMAD_VERSION"/"$NOMAD_ZIPFILE

cd /tmp

wget -p /tmp $NOMAD_URL
unzip -d /tmp $NOMAD_ZIPFILE

sudo chown root:root /tmp/nomad

mv nomad /usr/local/bin

mv /tmp/nomad /usr/local/bin/

# nomad -autocomplete-install
# complete -C /usr/local/bin/nomad nomad

useradd --system --home /etc/nomad.d --shell /bin/false nomad
mkdir --parents /opt/nomad
chown --recursive nomad:nomad /opt/nomad

touch /etc/systemd/system/nomad.service

