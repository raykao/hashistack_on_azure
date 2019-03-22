#!/bin/bash

# Expects that the config-dir and data-dir are both created at consul install/config time
# Expects that jq is installed on system
# Expects that the VM has Azure Managed (Service) Identity (MSI) Associated with it

# This step should probably introduced upon provisioning the VM i.e. via Cloud-Init - NOT when creating the VM image

export CONSUL_GOSSIP_ENCRYPT_KEY="${consul_gossip_encrypt_key}"
export CONSUL_VMSS_RG="${consul_vmss_rg}"
export CONSUL_VMSS_NAME="${consul_vmss_name}"

export AZURE_SUBSCRIPTION_ID="${azure_subscription_id}"

bash /opt/consul/bin/run_consul.sh