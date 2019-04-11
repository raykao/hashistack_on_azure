#!/bin/bash

# Terraform variables will be "injected" via interpolation and data source configuration in main template
export IS_SERVER="${is_server}"
export CLUSTER_VM_COUNT="${cluster_vm_count}"

export AZURE_SUBSCRIPTION_ID="${azure_subscription_id}" # gives the full subID with prepended "/subscription/<id>"
export AZURE_TENANT_ID="${azure_tenant_id}"

export CONSUL_VMSS_NAME="${consul_vmss_name}"
export CONSUL_VMSS_RG="${consul_vmss_rg}"
export CONSUL_DC_NAME="${consul_dc_name}"
export CONSUL_ENCRYPT_KEY='${consul_encrypt_key}'
export CONSUL_MASTER_TOKEN="${consul_master_token}"

export AKV_VAULT_NAME="${azure_key_vault_name}"
export AKV_KEY_NAME="${azure_key_vault_shamir_key_name}"

export VAULT_KEY_SHARES="${vault_key_shares}"
export VAULT_KEY_THRESHOLD="${vault_key_threshold}"
export VAULT_PGP_KEYS="${vault_pgp_keys}"

export NOMAD_ENCRYPT_KEY="${nomad_encrypt_key}"

export IPADDR="$(ip addr show eth0 | grep -Po 'inet \K[\d.]+')"

export ADMINUSER="${admin_user_name}"

########################
### Helper Functions ###
########################
### For non-worker nodes (Consul, Vault or Nomad Masters Control Servers) - remove docker.  Called in respective $hashiapp-server functions
uninstall_docker() {
  sudo apt-get purge -y docker-ce
  sudo rm -rf /var/lib/docker
  sudo groupdel docker
  sudo rm -rf /var/run/docker.sock
  sudo rm /usr/bin/docker
}

### Remove the hashiapps not required for respective server types (e.g. Consul doesn't need vault or nomad agents installed)
disable_hashiapp() {
  sudo rm -rf "/opt/$1" || true
  sudo rm "/etc/systemd/system/$1.service" || true
}

### Set file permissions and enable service for HashiApp [consul, vault, nomad]
enable_hashiapp() {
  sudo usermod -aG "$1" "$ADMINUSER" 2>&1 | sudo tee /opt/usermod.txt
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
HASHIAPP="$IS_SERVER"
AZURE_SUBSCRIPTION_ID="$AZURE_SUBSCRIPTION_ID"
CONSUL_VMSS_RG="$CONSUL_VMSS_RG"
CONSUL_VMSS_NAME="$CONSUL_VMSS_NAME"
EOF

  sudo cat /opt/consul/bin/run_consul.sh >> /tmp/file.txt

  sudo cp /tmp/file.txt /opt/consul/bin/run_consul.sh

  ## Add Consul default settings to all worker and all server types (Consul, Vault, Nomad)
  sudo cat > /opt/consul/config/consul.hcl <<EOF
datacenter = "$CONSUL_DC_NAME"
encrypt = "$CONSUL_ENCRYPT_KEY"
encrypt_verify_incoming = true
encrypt_verify_outgoing = true

data_dir = "/opt/consul/data"

acl {
  enabled = true
  default_policy = "deny"
  down_policy = "extend-cache"
  enable_token_persistence = true
}
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
bootstrap_expect = $CLUSTER_VM_COUNT
ui = false
connect {
    enabled = true 
}
EOF

sudo cat > /opt/consul/config/acl.hcl <<EOF 
acl {
  tokens {
    master = "$CONSUL_MASTER_TOKEN"
  }
}
EOF

  echo "export CONSUL_HTTP_TOKEN='$CONSUL_MASTER_TOKEN'" >> /home/$ADMINUSER/.bashrc

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
  token = "$CONSUL_MASTER_TOKEN"
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

sleep 120

sudo vault operator init \
  -address="http://127.0.0.1:8200" \
  -recovery-shares=$VAULT_KEY_SHARES \
  -recovery-threshold=$VAULT_KEY_THRESHOLD \
  -recovery-pgp-keys=$VAULT_PGP_KEYS 2>&1 | sudo tee /opt/vault_recovery_keys.txt

export RECOVERY_KEYS=($(head -n -5 /opt/vault_recovery_keys.txt | awk '{ print $4 }'))
export VAULT_ROOT_TOKEN=$${RECOVERY_KEYS[-1]}
export users=()

unset 'RECOVERY_KEYS[$${#RECOVERY_KEYS[@]}-1]'

rm /opt/vault_recovery_keys.txt

sudo echo "export VAULT_ADDR='http://127.0.0.1:8200'" >> /home/$ADMINUSER/.bashrc
sudo echo "export VAULT_TOKEN='$VAULT_ROOT_TOKEN'" >> /home/$ADMINUSER/.bashrc

OLDIFS=$IFS
IFS=","
keybase=($VAULT_PGP_KEYS)
IFS=$OLDIFS

for index in "$${!keybase[@]}"; do
  users+=($(echo $${keybase[index]} | awk -F: '{print $2}'))
done

for index in "$${!RECOVERY_KEYS[@]}"; do
  echo "$${users[$index]}: $${RECOVERY_KEYS[$index]}" >> /opt/vault_recovery_keys.txt
done

Setup Consul Secrets Backend/Engine
sudo vault secrets enable consul
sudo vault write consul/config/access \
  -address="127.0.0.1:8500" \
  -token=$CONSUL_MASTER_TOKEN

}

###############################
#### Nomad Common Settings ####
###############################
configure_nomad_common() {
  disable_hashiapp "vault"
  configure_consul_agent

  sudo cat > /opt/nomad/config/common.hcl <<EOF
consul {
  server_service_name = "nomad"
  client_service_name = "nomad-client"
  address = "127.0.0.1:8500"
  auto_advertise      = true
  server_auto_join    = true
  client_auto_join    = true
}

data_dir = "/opt/nomad/data"
EOF

  enable_hashiapp "nomad"
}

####################################
#### Nomad Client ONLY settings ####
####################################

configure_nomad_client() {

  sudo cat > /opt/nomad/config/client.hcl <<EOF
client {
  enabled = true
  server_join {
    retry_max = 10
    retry_interval = "15s"
  }
}
EOF

  configure_nomad_common
}


####################################
#### Nomad Server ONLY settings ####
####################################
configure_nomad_server() {
  uninstall_docker

  ## Nomad Server Config

  sudo cat > /opt/nomad/config/server.hcl <<EOF
server {
  enabled          = true
  bootstrap_expect = $CLUSTER_VM_COUNT
  encrypt = "$NOMAD_ENCRYPT_KEY"
  server_join {
    retry_max = 10
    retry_interval = "15s"
  }
}
EOF
  
  configure_nomad_common
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