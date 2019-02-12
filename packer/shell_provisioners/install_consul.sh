#!/bin/bash

# Terraform variables will be "injected" via interpolation and data source configuration in main template

# Used for setting up Consul Server inter-node encrpyted settings
CONSUL_ENCRYPT="${consul_encrpyt}"
CONSUL_DATACENTER="${consul_datacenter}"
CONSUL_VERSION="${consul_version}"
CONSUL_DOWNLOAD_PATH="/tmp/consul_"$CONSUL_VERSION"_linux_amd64.zip"
CONSUL_DOWNLOAD_URL="https://releases.hashicorp.com/consul/"$CONSUL_VERSION"/consul_"$CONSUL_VERSION"_linux_amd64.zip"


# Used for getting cluster IP addresses for Consul bootstrapping/join
AZURE_SCALE_SET_NAME="${scale_set_name}"
AZURE_SUBSCRIPTION_ID="${subscription_id}"
AZURE_TENENT_ID="${tenant_id}"
AZURE_CLIENT_ID="${client_id}"
AZURE_SECRET_ACCESS_KEY="${secret_access_key}"

apt update

apt install -y unzip jq

wget -P /tmp "$CONSUL_DOWNLOAD_URL"

unzip -d /tmp "$CONSUL_DOWNLOAD_PATH"

chown root:root /tmp/consul

mv /tmp/consul /usr/local/bin/

consul -autocomplete-install
complete -C /usr/local/bin/consul consul

useradd --system --home /etc/consul.d --shell /bin/false consul
mkdir --parents /opt/consul
chown --recursive consul:consul /opt/consul

touch /etc/systemd/system/consul.service

cat >/etc/systemd/system/consul.service <<EOF
[Unit]
Description="HashiCorp Consul - A service mesh solution"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/consul.d/consul.hcl

[Service]
User=consul
Group=consul
ExecStart=/bin/bash /etc/consul.d/start-consul.sh
ExecReload=/usr/local/bin/consul reload
KillMode=process
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

mkdir --parents /etc/consul.d
chown --recursive consul:consul /etc/consul.d

touch /etc/consul.d/start-consul.sh
chmod 740 /etc/consul.d/start-consul.sh

cat >/etc/consul.d/start-consul.sh <<EOF
#!/usr/bin/env bash

export CONSUL_BIND_ADDR=$(ifconfig eth0 | grep "inet " | awk '{ print $2 }')

consul agent -config-dir=/etc/consul.d/ -bind=$CONSUL_BIND_ADDR
EOF

touch /etc/consul.d/consul.hcl
chmod 640 /etc/consul.d/consul.hcl

cat >/etc/consul.d/consul.hcl <<EOF
datacenter = "dc1"
data_dir = "/opt/consul"
encrypt = "$CONSUL_ENCRYPT"
retry_join = ["192.168.0.4", "192.168.0.5", "192.168.0.6"]
EOF
