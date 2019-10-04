## The Env Vars
# AZURE_SUBSCRIPTION_ID
# CONSUL_VMSS_RG
# CONSUL_VMSS_NAME
## were prepended to this script at provisioning time with Terraform via custom_data/cloud-init

AZURE_MSI_ENDPOINT="http://169.254.169.254/metadata/identity"
AZURE_MSI_OAUTH=$(curl -H "Metadata:true" $AZURE_MSI_ENDPOINT"/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.azure.com%2F")
AZURE_MSI_JWT=$(echo $AZURE_MSI_OAUTH | jq -r '.access_token')

# Base Consul Config Info
CONSUL_BASE_DIR="/opt/consul"
CONSUL_CONFIG_DIR=$CONSUL_BASE_DIR"/config"

# Setup ip address to bind Consul to
CONSUL_BIND_ADDR=$(ifconfig eth0 | grep "inet " | awk '{ print $2 }')

function getVMSSprivateIPAddresses () {
  consulRetryJoin=""
  vmssPrivateIPAddress=$(curl https://management.azure.com$AZURE_SUBSCRIPTION_ID/resourceGroups/$CONSUL_VMSS_RG/providers/Microsoft.Compute/virtualMachineScaleSets/$CONSUL_VMSS_NAME/networkInterfaces?api-version=2018-10-01 -H "Authorization: Bearer $AZURE_MSI_JWT" | jq -r '.value | .[] | .properties.ipConfigurations | .[] | .properties.privateIPAddress')

  for vmIP in $vmssPrivateIPAddress
  do
    consulRetryJoin+=" -retry-join $vmIP"
  done

  echo $consulRetryJoin
}

echo $(consul agent -config-dir="$CONSUL_CONFIG_DIR" -bind="$CONSUL_BIND_ADDR" $(getVMSSprivateIPAddresses))