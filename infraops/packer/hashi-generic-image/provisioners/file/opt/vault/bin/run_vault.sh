export VAULT_CONFIG_DIR="/opt/vault/config"
export IPADDR="$(ip addr show eth0 | grep -Po 'inet \K[\d.]+')"

vault -config="/opt/vault/config" -address=$IPADDR