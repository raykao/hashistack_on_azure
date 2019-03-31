#!/bin/bash

# Terraform variables will be "injected" via interpolation and data source configuration in main template
export IS_SERVER="${is_server}"
export AZURE_SUBSCRIPTION_ID="${azure_subscription_id}"
export CONSUL_VMSS_NAME="${consul_vmss_name}"
export CONSUL_VMSS_RG="${consul_vmss_rg}"
export CONSUL_DC_NAME="${consul_dc_name}"
export CONSUL_ENCRYPT_KEY="${consul_encrypt_key}"

###############################
### Server or Worker setup ####
###############################
if [ -z "$IS_SERVER" ]; then
  # If the server type isn't set (empty or false)...make it a worker (aka nomad agent)
  configure_nomad_agent
else

case $IS_SERVER in
  consul)
    configure_consul_server
    ;;
  vault)
    configure_vault_server
    ;;
  nomad)
    configure_nomad_server
    ;;
  *)
    # If it's not a consul, vault or nomad server...it's default a worker (aka nomad agent)...
    configure_nomad_agent
    ;;
esac

fi
###############################
###############################
###############################

########################
### Helper Functions ###
########################
### For non-worker nodes (Consul, Vault or Nomad Masters Control Servers) - remove docker.  Called in respective $hashiapp-server functions
uninstall_docker() {
  sudo apt-get purge docker-ce
  sudo rm -rf /var/lib/docker
}

### Remove the hashiapps not required for respective server types (e.g. Consul doesn't need vault or nomad agents installed)
disable_hashiapp() {
  sudo rm -rf "/opt/$1"
  sudo rm "/etc/systemd/system/$1.service"
}

### Set file permissions and enable service for HashiApp [consul, vault, nomad]
enable_hashiapp() {
  sudo chown -R $1:$1 /opt/$1
  sudo systemctl enable $1
  sudo systemctl restart $1
  sudo systemctl status $1
}

#############################
#### Consul Agent basics ####
#############################
configure_consul_agent() {
  # At terraform provisioning time, Azure Subscription ID, VMSS Name && RG values are written to the /opt/consul/bin/run_consul.sh script which systemd.service uses to boot Consul at Start/Restart. These values are needed to auto check the Consul Server VMSS cluster ip addresses for dynamic retry joining via Azure Manages Service Identity assigned to the VM.  Consul Server Cluster IP addresses can by dynamic and change as a result of auto/manual scaling of Server Nodes.  We need to run this dynamically on boot to ensure we find at least 1 known good IP address to join to the Consul Cluster.
  sudo echo -e "AZURE_SUBSCRIPTION_ID='$AZURE_SUBSCRIPTION_ID'\nCONSUL_VMSS_RG='$CONSUL_VMSS_RG'\nCONSUL_VMSS_NAME='$CONSUL_VMSS_NAME'\n$(cat /opt/consul/bin/run_consul.sh)" > /opt/consul/bin/run_consul.sh

  ## Add Consul default settings to all worker and all server types (Consul, Vault, Nomad)
sudo cat >/opt/consul/config/consul.hcl <<EOF
  datacenter = "$CONSUL_DC_NAME"
  encrypt = "$CONSUL_ENCRYPT_KEY"
  data_dir = "/opt/consul/data"
EOF

  enable_hashiapp "consul"
}


#################################
#### Consul Server specifics ####
#################################
configure_consul_server() {
  disable_hashiapp "vault"
  uninstall_docker
  disable_hashiapp "nomad"

  ## Consul Server Config
sudo cat >/opt/consul/config/server.hcl <<EOF
  server = true
  bootstrap_expect = 3
  ui = true
  connect {
    enabled = true
  }
EOF

  configure_consul_agent
}


############################
#### Vault Agent basics ####
############################
configure_vault_agent() {
  configure_consul_agent
  enable_hashiapp "vault"
}

################################
#### Vault Server specifics ####
################################
configure_vault_server() {
  uninstall_docker
  disable_hashiapp "nomad"

  ## Vault Server Config
  configure_vault_agent
}
############################
#### Nomad Agent basics ####
############################
configure_nomad_agent() {
  configure_vault_agent
  enable_hashiapp "nomad"
}
################################
#### Nomad Server specifics ####
################################
configure_nomad_server() {
  uninstall_docker

  ## Nomad Server Config
  configure_nomad_agent
}