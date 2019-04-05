terraform {
  required_version = ">= 0.11.11"
}

provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version = "=1.23.0"
}

locals {
  suffix = "${random_pet.suffix.id}"
}

resource "random_pet" "suffix" {
  separator = "-"
}

resource "azurerm_resource_group" "hashicluster" {
  name     = "hashicluster-${local.suffix}"
  location = "${var.AZURE_DC_LOCATION}"
}

resource "azurerm_virtual_network" "hashicluster" {
  name                = "${azurerm_resource_group.hashicluster.name}-network"
  resource_group_name = "${azurerm_resource_group.hashicluster.name}"
  location            = "${azurerm_resource_group.hashicluster.location}"
  address_space       = ["10.0.0.0/8"]
}

module "jumpbox_server" {
  source = "./modules/jumpbox"

  suffix = "${local.suffix}"
  resource_group_location = "${azurerm_resource_group.hashicluster.location}"
  
  admin_name = "${var.ADMIN_NAME}"
  ssh_key = "${var.SSH_PUBLIC_KEY}"
  
  virtual_network_name = "${azurerm_virtual_network.hashicluster.name}"
  virtual_network_resource_group_name = "${azurerm_resource_group.hashicluster.name}"
  virtual_network_resource_group_location = "${azurerm_resource_group.hashicluster.location}"

  managed_disk_id = "${var.HASHI_MANAGED_VM_IMAGE_NAME}"

  subnet_prefix = "10.0.0.48/29"
}
module "consul_servers" {
  source = "./modules/hashicluster"
  
  hashiapp = "consul"
  cluster_name = "${var.CONSUL_VMSS_NAME}"
  resource_group_name = "${var.CONSUL_VMSS_RG}"
  resource_group_location = "${azurerm_resource_group.hashicluster.location}"  

  consul_vmss_name = "${var.CONSUL_VMSS_NAME}"
  consul_vmss_rg = "${var.CONSUL_VMSS_RG}"
  consul_encrypt_key = "${var.CONSUL_ENCRYPT_KEY}"

  cluster_vm_count = "${var.CONSUL_SERVER_CLUSTER_VM_COUNT}"
  cluster_vm_size = "${var.CONSUL_SERVER_CLUSTER_VM_SIZE}"
  cluster_vm_image_reference = "${var.HASHI_MANAGED_VM_IMAGE_NAME}"

  admin_user_name = "${var.ADMIN_NAME}"
  ssh_public_key = "${var.SSH_PUBLIC_KEY}"

  vnet_name = "${azurerm_virtual_network.hashicluster.name}"
  vnet_resource_group_name = "${azurerm_resource_group.hashicluster.name}"
  subnet_prefix = "10.0.0.0/28"
}

module "vault_servers" {
  source = "./modules/hashicluster"
  
  hashiapp = "vault"
  cluster_name = "vault-servers"
  resource_group_name = "vault-servers"
  resource_group_location = "${azurerm_resource_group.hashicluster.location}"  

  consul_vmss_name = "${var.CONSUL_VMSS_NAME}"
  consul_vmss_rg = "${var.CONSUL_VMSS_RG}"
  consul_encrypt_key = "${module.consul_servers.consul_encrypt_key}"

  cluster_vm_count = "3"
  cluster_vm_size = "${var.CONSUL_SERVER_CLUSTER_VM_SIZE}"
  cluster_vm_image_reference = "${var.HASHI_MANAGED_VM_IMAGE_NAME}"

  vault_key_shares = "${var.VAULT_KEY_SHARES}"
  vault_key_threshold = "${var.VAULT_KEY_THRESHOLD}"
  vault_pgp_keys = "${var.VAULT_PGP_KEYS}"

  admin_user_name = "${var.ADMIN_NAME}"
  ssh_public_key = "${var.SSH_PUBLIC_KEY}"

  vnet_name = "${azurerm_virtual_network.hashicluster.name}"
  vnet_resource_group_name = "${azurerm_resource_group.hashicluster.name}"
  subnet_prefix = "10.0.0.16/28"
}


module "nomad_servers" {
  source = "./modules/hashicluster"
  
  hashiapp = "nomad"
  cluster_name = "nomad-servers"
  resource_group_name = "nomad-servers"
  resource_group_location = "${azurerm_resource_group.hashicluster.location}"  

  consul_vmss_name = "${var.CONSUL_VMSS_NAME}"
  consul_vmss_rg = "${var.CONSUL_VMSS_RG}"
  consul_encrypt_key = "${module.consul_servers.consul_encrypt_key}"

  nomad_server_vmss_name = "nomad-servers"
  nomad_server_vmss_rg_name = "nomad-servers"

  cluster_vm_count = "3"
  cluster_vm_size = "${var.CONSUL_SERVER_CLUSTER_VM_SIZE}"
  cluster_vm_image_reference = "${var.HASHI_MANAGED_VM_IMAGE_NAME}"

  admin_user_name = "${var.ADMIN_NAME}"
  ssh_public_key = "${var.SSH_PUBLIC_KEY}"

  vnet_name = "${azurerm_virtual_network.hashicluster.name}"
  vnet_resource_group_name = "${azurerm_resource_group.hashicluster.name}"
  subnet_prefix = "10.0.0.32/28"
}

module "worker_nodes" {
  source = "./modules/hashicluster"
  
  hashiapp = "workernode"
  cluster_name = "worker-nodes"
  resource_group_name = "worker-nodes"
  resource_group_location = "${azurerm_resource_group.hashicluster.location}"  

  consul_vmss_name = "${var.CONSUL_VMSS_NAME}"
  consul_vmss_rg = "${var.CONSUL_VMSS_RG}"
  consul_encrypt_key = "${module.consul_servers.consul_encrypt_key}"

  nomad_server_vmss_name = "${module.nomad_servers.cluster_name}"
  nomad_server_vmss_rg_name = "${module.nomad_servers.cluster_resource_group_name}"

  cluster_vm_count = "3"
  cluster_vm_size = "${var.CONSUL_SERVER_CLUSTER_VM_SIZE}"
  cluster_vm_image_reference = "${var.HASHI_MANAGED_VM_IMAGE_NAME}"

  admin_user_name = "${var.ADMIN_NAME}"
  ssh_public_key = "${var.SSH_PUBLIC_KEY}"

  vnet_name = "${azurerm_virtual_network.hashicluster.name}"
  vnet_resource_group_name = "${azurerm_resource_group.hashicluster.name}"
  subnet_prefix = "10.1.0.0/17"
}