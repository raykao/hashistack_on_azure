
export IPADDR="$(ip addr show eth0 | grep -Po 'inet \K[\d.]+')"
export VAULT_CONFIG_DIR="/opt/vault/config"
export VAULT_API_ADDR="https://$IPADDR:8200"

sudo cat > /opt/vault/config/listener.hcl <<EOF
listener "tcp" {
  address     = "$IPADDR:8200"
  tls_disable = 1
}
EOF

vault server -config="/opt/vault/config"