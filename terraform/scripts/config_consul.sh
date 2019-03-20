#!/bin/bash

# Terraform variables will be "injected" via interpolation and data source configuration in main template

# Used for setting up Consul Server inter-node encrpyted settings
export CONSUL_ENCRYPT="${consul_encrpyt}"
export CONSUL_DATACENTER="${consul_datacenter}"

# Used for getting cluster IP addresses for Consul bootstrapping/join
export AZURE_SCALE_SET_NAME="${scale_set_name}"
export AZURE_SUBSCRIPTION_ID="${subscription_id}"
export AZURE_TENENT_ID="${tenant_id}"
export AZURE_CLIENT_ID="${client_id}"
export AZURE_SECRET_ACCESS_KEY="${secret_access_key}"
export AZURE_DC_NAME="${dc_name}"

touch /etc/systemd/system/consul.service

cat >/etc/systemd/system/consul.service <<EOF
[Unit]
Description="HashiCorp Consul - A service mesh solution"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/opt/consul/config/consul.hcl

[Service]
User=consul
Group=consul
ExecStart=/bin/bash /opt/consul/config/start-consul.sh
ExecReload=/usr/local/bin/consul reload
KillMode=process
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

mkdir --parents /opt/consul/config
chown --recursive consul:consul /opt/consul/config

touch /opt/consul/config/start-consul.sh
chmod 740 /opt/consul/config/start-consul.sh

cat >/opt/consul/config/start-consul.sh <<EOF
#!/usr/bin/env bash

export CONSUL_BIND_ADDR=$(ifconfig eth0 | grep "inet " | awk '{ print $2 }')

consul agent -config-dir=/opt/consul/config/ -bind=$CONSUL_BIND_ADDR
EOF

touch /opt/consul/config/consul.hcl
chmod 640 /opt/consul/config/consul.hcl

cat >/opt/consul/config/consul.hcl <<EOF
datacenter = "$AZURE_DC_NAME"
data_dir = "/opt/consul/data"
encrypt = "$CONSUL_ENCRYPT"
EOF
