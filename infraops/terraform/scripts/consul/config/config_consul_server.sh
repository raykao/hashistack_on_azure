#!/bin/bash

# Terraform variables will be "injected" via interpolation and data source configuration in main template
AZURE_SUBSCRIPTION_ID="${subscription_id}"

CONSUL_VMSS_NAME="${vmss_name}"
CONSUL_VMSS_RG="${vmss_rg}"
CONSUL_DC_NAME="${consul_dc_name}"
CONSUL_SERVER="${consul_server}"

CONSUL_GOSSIP_ENCRYPT_KEY="${consul_encrpyt}"


echo -e "AZURE_SUBSCRIPTION_ID='$AZURE_SUBSCRIPTION_ID'\nCONSUL_VMSS_RG='$CONSUL_VMSS_RG'\nCONSUL_VMSS_NAME='$CONSUL_VMSS_NAME'\nCONSUL_GOSSIP_ENCRYPT_KEY='$CONSUL_GOSSIP_ENCRYPT_KEY'\n$(cat /opt/consul/bin/run_consul.sh)" > /opt/consul/bin/run_consul.sh

# cat >/opt/consul/config/start-consul.sh <<EOF
# #!/usr/bin/env bash

# export CONSUL_BIND_ADDR=$(ifconfig eth0 | grep "inet " | awk '{ print $2 }')

# consul agent -config-dir=/opt/consul/config/ -bind=$CONSUL_BIND_ADDR
# EOF

# Add the basic serf encrpytion vaules
cat >>/opt/consul/config/consul.hcl <<EOF
dc = "$CONSUL_DC_NAME"
encrypt = "$CONSUL_ENCRYPT"
EOF

if [ ! -z "$CONSUL_SERVER" ]; then
cat >>/opt/consul/config/server.hcl <<EOF
server = true
EOF
fi

# Ensure that the consul user owns it's own dir
chown --recursive consul:consul /opt/consul
