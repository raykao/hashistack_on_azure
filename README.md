# Hashistack on Azure

This repository is used as a learning guide to deploy an opinionated Hashicorp technology stack on Azure.  It is meant to deploy a brand new cluster using:

- [Packer](https://www.packer.io/) to create a standardized VM image for all machines in the cluster as an [Azure Managed Image](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/build-image-with-packer)
- [Terraform](https://www.terraform.io/) to provision 
    - [Azure Virtual Machine Scale Set](https://docs.microsoft.com/en-us/azure/virtual-machine-scale-sets/overview) (aka "VMSS") clusters for:
      - [Consul](https://www.consul.io/) Servers - for Service Discovery, Service Mesh and Configuration Storage
      - [Vault](https://www.vaultproject.io/) Servers - for Secrets Management of certificates and Dynamic Credentials/Logins for cluster deployed services
      - [Nomad](https://www.nomadproject.io/) Servers - for Application Deployment and Scheduling in the Cluster
      - Worker Cluster - Which includes Consul and Nomad in client mode as well as Docker
      - Jumpbox/Basition VM to do Ops/Sys-admin tasks post deployment as necessary
    - [Azure Key Vault](https://docs.microsoft.com/en-ca/azure/key-vault/) for [Hashicorp Vault auto-unseal](https://learn.hashicorp.com/vault/operations/autounseal-azure-keyvault) and as a backend store for Hashicorp Vault
    - [Azure Managed Service Identity](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/) to give the VMs in the cluster their own group identity to access Azure Services without hardcoding the credentials on/into the VMs
    - [Azure Virtual Network](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview) - One VNET to deploy them all
    - [Azure Subnets](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-vnet-plan-design-arm#subnets) - Each cluster (i.e. Consul, Vault, Nomad, Workers and Jumpbox) will be deployed into their own subnet


## Architecture

- (3) Consul Servers - deployed as a VMSS
- (3) Vault Servers - deployed as a VMSS
- (3) Nomad Servers - deployed as a VMSS
- (3) Worker Nodes - deployed as a VMSS
    - Consul, Nomad and Docker are installed on these machines

## Tasks/Solutions

- Task: Create a standard disk image for deployment of cluster
    - Solution: Use Hashicorp Packer to generate a baseline "Gold" VM image with all the binaries/tools (Consul, Vault, Nomad, Docker, jq), base config files and systemd service files pre-installed for faster deployment
- Task: Declaratively deploy infrastructure and provision cluster
    - Solution: Use Terraform to define the cluster and deploy VMSS and base Azure Services
- Task: How do we securely save/store the initial Consul Recovery Keys and Root Token?
    - Solution: 
      - (1) save it to a blob storage account where the MSI has write-only access
      - (2) save it to an AKV where the MSI has write-only access
      - (3) use something like Keybase to send a GPG encrypted message to a user/admin??