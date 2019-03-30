#!/bin/bash

# Terraform variables will be "injected" via interpolation and data source configuration in main template
AZURE_SUBSCRIPTION_ID="${subscription_id}"
IS_CONSUL_SERVER="${consul_server}"
CONSUL_VMSS_NAME="${vmss_name}"
CONSUL_VMSS_RG="${vmss_rg}"
CONSUL_DC_NAME="${consul_dc_name}"
CONSUL_GOSSIP_ENCRYPT_KEY="${consul_encrpyt}"

# At terraform provisioning time, Azure Subscription ID, VMSS Name && RG values are written to the /opt/consul/bin/run_consul.sh script which systemd.service uses to boot Consul at Start/Restart. These values are needed to auto check the Consul Server VMSS cluster ip addresses for dynamic retry joining via Azure Manages Service Identity assigned to the VM.  Consul Server Cluster IP addresses can by dynamic and change as a result of auto/manual scaling of Server Nodes.  We need to run this dynamically on boot to ensure we find at least 1 known good IP address to join to the Consul Cluster.
sudo echo -e "AZURE_SUBSCRIPTION_ID='$AZURE_SUBSCRIPTION_ID'\nCONSUL_VMSS_RG='$CONSUL_VMSS_RG'\nCONSUL_VMSS_NAME='$CONSUL_VMSS_NAME'\n$(cat /opt/consul/bin/run_consul.sh)" > /opt/consul/bin/run_consul.sh

# Add Consul default settings (Agent && Server Modes)
sudo cat >/opt/consul/config/consul.hcl <<EOF
datacenter = "$CONSUL_DC_NAME"
encrypt = "$CONSUL_GOSSIP_ENCRYPT_KEY"
data_dir = "/opt/consul/data"
EOF

# Add Consul Server Mode specific settings
if [ ! -z "$IS_CONSUL_SERVER" ]; then
sudo cat >/opt/consul/config/server.hcl <<EOF
server = true
bootstrap_expect = 3
ui = true
connect {
  enabled = true
}
EOF
fi

# Ensure that the consul user/group owns its own dir/settings
sudo chown -R consul:consul /opt/consul

# Enable Consul with systemd.service and start it up
sudo systemctl enable consul
sudo systemctl restart consul
sudo systemctl status consul