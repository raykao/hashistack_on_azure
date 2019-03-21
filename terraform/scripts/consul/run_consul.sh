#!/bin/bash

# Expects that the config-dir and data-dir are both created at consul install/config time
# Expects that jq is installed on system
# Expects that the VM has Azure Managed (Service) Identity (MSI) Associated with it

# This step should probably introduced upon provisioning the VM i.e. via Cloud-Init - NOT when creating the VM image

export CONSUL_VMSS_NAME="${consul_vmss_name}"
export CONSUL_VMSS_RG="${consul_vmss_rg}"
export AZURE_SUBSCRIPTION_ID="${azure_subscription_id}"

export AZURE_MSI_ENDPOINT="http://169.254.169.254/metadata/identity"
export AZURE_MSI_OAUTH=$(curl -H "Metadata:true" $AZURE_MSI_ENDPOINT"/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.azure.com%2F")
export AZURE_MSI_JWT=$($AZURE_MSI_OAUTH | jq -r '.access_token')

# Get Consul Server VMSS Cluster ip-pool to auto-rejoin
# curl https://management.azure.com/subscriptions/<SUBSCRIPTION ID>/resourceGroups/<RESOURCE GROUP>?api-version=2016-09-01 -H "Authorization: Bearer <ACCESS TOKEN>" 
# export CONSUL_SERVERS=""

# Create a 16-byte base 64 encoded encryption key for Consul's Gossip protocol (https://www.consul.io/docs/agent/encryption.html#gossip-encryption)
# export CONSUL_GOSSIP_ENCRYPT=$(consul keygen)


function getVMSSIDs(){
  curl https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$CONSUL_VMSS_RG/providers/Microsoft.Compute/virtualMachineScaleSets/$CONSUL_VMSS_NAME/virtualMachines?api-version=2016-09-01 -H "Authorization: Bearer $AZURE_MSI_JWT" 

}

consul agent \
  -config-dir="/opt/consul/config" \
  -data-dir="/opt/consul/data" \
  -encrypt=$CONSUL_GOSSIP_ENCRYPT \
  -retry-join="$CONSUL_SERVERS"