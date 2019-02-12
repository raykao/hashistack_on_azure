#!/bin/bash

# Expects that the config-dir and data-dir are both created at consul install/config time
# Expects that jq is installed on system
# Expects that the VM has Azure Managed (Service) Identity (MSI) Associated with it

export AZURE_MI_ENDPOINT="http://169.254.169.254/metadata/identity"
export AZURE_MI_OAUTH=$(curl -H "Metadata:true" $AZURE_MI_ENDPOINT"/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.azure.com%2F")
export AZURE_JWT=$($AZURE_MI_OAUTH | jq ".access_token")

curl https://management.azure.com/subscriptions/<SUBSCRIPTION ID>/resourceGroups/<RESOURCE GROUP>?api-version=2016-09-01 -H "Authorization: Bearer <ACCESS TOKEN>" 


consul agent -config-dir="/etc/config.d" -data-dir="/opt/consul"