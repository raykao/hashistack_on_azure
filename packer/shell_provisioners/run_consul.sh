#!/bin/bash

# Expects that the config-dir and data-dir are both created at consul install/config time
# Expects that jq is installed on system
# Expects that the VM has Azure Managed (Service) Identity (MSI) Associated with it

# This step should probably introduced upon provisioning the VM i.e. via Cloud-Init - NOT when creating the VM image

export AZURE_MI_ENDPOINT="http://169.254.169.254/metadata/identity"
export AZURE_MI_OAUTH=$(curl -H "Metadata:true" $AZURE_MI_ENDPOINT"/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.azure.com%2F")
export AZURE_JWT=$($AZURE_MI_OAUTH | jq ".access_token")

# Get Consul Server VMSS Cluster ip-pool to auto-rejoin
# curl https://management.azure.com/subscriptions/<SUBSCRIPTION ID>/resourceGroups/<RESOURCE GROUP>?api-version=2016-09-01 -H "Authorization: Bearer <ACCESS TOKEN>" 
# export CONSUL_SERVERS=""

# Create a 16-byte base 64 encoded encryption key for Consul's Gossip protocol (https://www.consul.io/docs/agent/encryption.html#gossip-encryption)
# export CONSUL_GOSSIP_ENCRYPT=$(consul keygen)


consul agent \
  -config-dir="/etc/config.d" \
  -data-dir="/opt/consul" \
  -encrypt=$CONSUL_GOSSIP_ENCRYPT \
  -retry-join="$CONSUL_SERVERS"