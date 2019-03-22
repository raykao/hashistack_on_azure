# Example - Packer Managed VM Image Build

### Branch Build Status
Master: ![Master Branch Build Status](https://dev.azure.com/osscanada/azure_devops_demo/_apis/build/status/Packer%20Test%20Build%20Pipeline?branchName=master)

Test: ![Test Branch Build Status](https://dev.azure.com/osscanada/azure_devops_demo/_apis/build/status/Packer%20Test%20Build%20Pipeline?branchName=test)

## Required settings

### Azure Service Principal

An Azure Service Principal (aka. AAD App Registration or SP) is also required, and must be given enough permissions to create resource in your subscription or limited to a specific resource group.  In this example we give the SP a contributor role to allow it to create what it needs for simplicity.  Best Practice is to limit its scope to only what it needs.  You will need the values it outputs for later use

```shell
az ad sp create-for-rbac -n "<AZ_SERVICE_PRINCIPLE_NAME>" --role <e.g. contributor> --scopes /subscriptions/<YOUR_AZ_SUBSCRIPTION_ID>

# example output:
{
    "client_id": "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee", # Maps to client_id in Packer Config
    "client_secret": "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee", # Maps to client_secret in Packer Config
    "tenant_id": "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
}
```

### Azure Resource Group

An Azure Resource Group (RG) is required to store the managed image artifact created by Packer.  Use the following command to generate an RG.

```
az group create --name <AZ_PACKER_RESOURCE_GROUP_NAME> --location <AZ_DC_LOCATION>
```

### Environment Variables and Config Settings

The example [Packer JSON build file](base_image.json) expects that you have the following values entered/passed into your build environment.  In [Azure DevOps](https://dev.azure.com), you can enter these into the variables for each of the pipelines that runs the ```packer build``` command, or create a [variable group](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/variable-groups?view=azure-devops&tabs=yaml) to link the variables to multiple pipelines that will leverage the values.  For more information about how to set/save and leverage Environment Variables, or how to set these values at run time with the ```packer build -var 'key=value'``` syntax, see the [Packer Setting Variables](https://www.packer.io/docs/templates/user-variables.html#setting-variables) documentation.

The below shell example is here as a convenience.

```shell
export AZ_CLIENT_ID="aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee" # provided from the az ad sp create command for az ad sp create command for Service Princpal (SP) output from above
export AZ_CLIENT_SECRET="aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee" # provided from the az ad sp create command for Service Princple (SP) output from above
export AZ_SUBSCRIPTION_ID="aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee" # provided from the az ad sp create command for Service Princple (SP) output from above
export AZ_TENANT_ID="aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee" # provided from the az ad sp create command for Service Princple (SP) output from above
export AZ_PACKER_RESOURCE_GROUP_NAME="resource_group_name_to_store_your_managed_image" # provided from the az group create command above
export AZ_OS_TYPE="Linux"
export AZ_IMAGE_PUBLISHER="Canonical"
export AZ_IMAGE_OFFER="UbuntuServer"
export AZ_IMAGE_SKU="18.04-LTS"
export AZ_DC_LOCATION="canada central"
export AZ_VM_SIZE="Standard_DS2_v2"
```