#!/bin/bash

# Terraform variables will be "injected" via interpolation and data source configuration in main template
export IS_SERVER="${is_server}"
export AZURE_SUBSCRIPTION_ID="${azure_subscription_id}" # gives the full subID with prepended "/subscription/<id>"
export AZURE_TENANT_ID="${azure_tenant_id}"
export CONSUL_VMSS_NAME="${consul_vmss_name}"
export CONSUL_VMSS_RG="${consul_vmss_rg}"
export CONSUL_DC_NAME="${consul_dc_name}"
export CONSUL_ENCRYPT_KEY="${consul_encrypt_key}"

export AKV_VAULT_NAME="${azure_key_vault_name}"
export AKV_KEY_NAME="${azure_key_vault_shamir_key_name}"

export VAULT_KEY_SHARES="${vault_key_shares}"
export VAULT_KEY_THRESHOLD="${vault_key_threshold}"
export VAULT_PGP_KEYS="${vault_pgp_keys}"

export NOMAD_VMSS_NAME="${nomad_vmss_name}"
export NOMAD_VMSS_RG="${nomad_vmss_rg}"

export IPADDR="$(ip addr show eth0 | grep -Po 'inet \K[\d.]+')"

sudo echo $(whoami) > /opt/whoami
sudo cat /etc/passwd > /opt/passwd 

########################
### Helper Functions ###
########################
### For non-worker nodes (Consul, Vault or Nomad Masters Control Servers) - remove docker.  Called in respective $hashiapp-server functions
uninstall_docker() {
  sudo apt-get purge docker-ce || true
  sudo rm -rf /var/lib/docker || true
}

### Remove the hashiapps not required for respective server types (e.g. Consul doesn't need vault or nomad agents installed)
disable_hashiapp() {
  sudo rm -rf "/opt/$1" || true
  sudo rm "/etc/systemd/system/$1.service" || true
}

### Set file permissions and enable service for HashiApp [consul, vault, nomad]
enable_hashiapp() {
  sudo chown -R $1:$1 /opt/$1
  sudo chmod -R 750 /opt/$1

  sudo systemctl enable $1
  sudo systemctl restart $1
}

#############################
#### Consul Agent basics ####
#############################
configure_consul_agent() {
  # At terraform provisioning time, Azure Subscription ID, VMSS Name && RG values are written to the /opt/consul/bin/run_consul.sh script which systemd.service uses to boot Consul at Start/Restart. These values are needed to auto check the Consul Server VMSS cluster ip addresses for dynamic retry joining via Azure Manages Service Identity assigned to the VM.  Consul Server Cluster IP addresses can by dynamic and change as a result of auto/manual scaling of Server Nodes.  We need to run this dynamically on boot to ensure we find at least 1 known good IP address to join to the Consul Cluster.
  # sudo sed -i "1s/^/AZURE_SUBSCRIPTION_ID='$AZURE_SUBSCRIPTION_ID'\nCONSUL_VMSS_RG='$CONSUL_VMSS_RG'\nCONSUL_VMSS_NAME='$CONSUL_VMSS_NAME'\n/" /opt/consul/bin/run_consul.sh
  
  sudo cat > /tmp/file.txt <<EOF
AZURE_SUBSCRIPTION_ID="$AZURE_SUBSCRIPTION_ID"
CONSUL_VMSS_RG="$CONSUL_VMSS_RG"
CONSUL_VMSS_NAME="$CONSUL_VMSS_NAME"
EOF

  sudo cat /opt/consul/bin/run_consul.sh >> /tmp/file.txt

  sudo mv /tmp/file.txt /opt/consul/bin/run_consul.sh

  ## Add Consul default settings to all worker and all server types (Consul, Vault, Nomad)
  sudo cat > /opt/consul/config/consul.hcl <<EOF
datacenter = "$CONSUL_DC_NAME"
encrypt = "$CONSUL_ENCRYPT_KEY"
data_dir = "/opt/consul/data"
retry_join = ["provider=azure tenant_id=$AZURE_TENANT_ID subscription_id=$AZURE_SUBSCRIPTION_ID resource_group=$CONSUL_VMSS_RG vm_scale_set=$CONSUL_VMSS_NAME"]
EOF

  enable_hashiapp "consul"
}
#################################
#### Consul Server specifics ####
#################################
configure_consul_server() {
  uninstall_docker
  disable_hashiapp "vault"
  disable_hashiapp "nomad"

  ## Consul Server Config
  sudo cat > /opt/consul/config/server.hcl <<EOF 
server = true
bootstrap_expect = 3
ui = true
connect {
    enabled = true 
}
EOF

  configure_consul_agent
}

################################
#### Vault Server specifics ####
################################
configure_vault_server() {
  uninstall_docker
  disable_hashiapp "nomad"

  sudo cat > /opt/vault/config/storage.hcl <<EOF
storage "consul" {
  address = "127.0.0.1:8500"
  path    = "vault"
}
EOF

  sudo cat > /opt/vault/config/auto_unseal.hcl <<EOF
seal "azurekeyvault" {
  tenant_id      = "$AZURE_TENANT_ID"
  vault_name     = "$AKV_VAULT_NAME"
  key_name       = "$AKV_KEY_NAME"
}
EOF

  sudo cat > /opt/vault/config/server.hcl <<EOF
listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = true
}

api_addr = "http://$HOSTNAME:8200"
cluster_addr = "http://$HOSTNAME:8201"
EOF
  
  configure_consul_agent
  enable_hashiapp "vault"

  sudo vault operator init \
    -key-shares=$VAULT_KEY_SHARES \
    -key-threshold=$VAULT_KEY_THRESHOLD \
    -pgp-keys=$VAULT_PGP_KEYS 2>&1 | sudo tee /opt/vault_recovery_keys.txt
  sudo chmod 640 /opt/vault_recovery_keys.txt
}


############################
#### Nomad Agent basics ####
############################
configure_nomad_client() {
  disable_hashiapp "vault"

  sudo cat > /opt/nomad/config/client.hcl <<EOF
client {
  enabled = true
}
EOF

  sudo cat > /opt/nomad/config/consul.hcl <<EOF
consul {
  server_service_name = "nomad"
  client_service_name = "nomad-client"
  address = "127.0.0.1:8500"
  auto_advertise      = true
  server_auto_join    = true
  client_auto_join    = true
}

EOF


  configure_consul_agent
  enable_hashiapp "nomad"
}


################################
#### Nomad Server specifics ####
################################
configure_nomad_server() {
  uninstall_docker
  disable_hashiapp "vault"

  ## Nomad Server Config

  sudo cat > /opt/nomad/config/server.hcl <<EOF
server {
  enabled          = true
  bootstrap_expect = 3
  server_join {
    retry_join = ["provider=azure tenant_id=$AZURE_TENANT_ID subscription_id=$AZURE_SUBSCRIPTION_ID resource_group=$NOMAD_VMSS_RG vm_scale_set=$NOMAD_VMSS_NAME"]
    retry_max = 3
    retry_interval = "15s"
  }
}
EOF

  configure_consul_agent
  enable_hashiapp "nomad"
}


###############################
### Server or Worker setup ####
###############################
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
    configure_nomad_client
    ;;
esac