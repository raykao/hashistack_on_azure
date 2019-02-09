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

cat >/etc/systemd/system/nomad.service <<EOF
# Modified from ref: https://github.com/hashicorp/nomad/blob/master/dist/systemd/nomad.service
[Unit]
Description=Nomad
Documentation=https://nomadproject.io/docs/
Wants=network-online.target
After=network-online.target

# If you are running Consul, please uncomment following Wants/After configs.
# Assuming your Consul service unit name is "consul"
#Wants=consul.service
#After=consul.service

[Service]
KillMode=process
KillSignal=SIGINT
ExecStart=/usr/local/bin/nomad agent -config /etc/nomad.d
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=2
StartLimitBurst=3
StartLimitIntervalSec=10
LimitNOFILE=65536
TasksMax=infinity

[Install]
WantedBy=multi-user.target
EOF