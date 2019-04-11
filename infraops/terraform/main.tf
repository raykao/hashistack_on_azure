terraform {
  required_version = ">= 0.11.11"
}

provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version = "=1.23.0"
}

locals {
  suffix = "${random_pet.suffix.id}"
  
  consul_cluster_name = "consul-servers-${local.suffix}"
  consul_rg_name = "consul-servers-${local.suffix}"
  vault_cluster_name  = "vault-servers-${local.suffix}"
  nomad_cluster_name = "nomad-servers-${local.suffix}"
  worker_cluster_name = "worker-nodes-${local.suffix}"

  vnet_address_space          = "10.0.0.0/8"
  consul_server_subnet_suffix = "10.0.0.0/28"
  vault_server_subnet_suffix  = "10.0.0.16/28"
  nomad_server_subnet_suffix  = "10.0.0.32/28"
  worker_nodes_subnet_suffix  = "10.1.0.0/17"
  jumpbox_subnet_prefix       = "10.0.0.48/29"
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
  address_space       = ["${local.vnet_address_space}"]
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

  subnet_prefix = "${local.jumpbox_subnet_prefix}"
}

module "consul_servers" {
  source = "./modules/hashicluster"
  
  hashiapp = "consul"
  cluster_name = "${local.consul_cluster_name}"
  resource_group_name = "${local.consul_rg_name}"
  resource_group_location = "${azurerm_resource_group.hashicluster.location}"  

  consul_vmss_name = "${local.consul_cluster_name}"
  consul_vmss_rg = "${local.consul_rg_name}"
  consul_encrypt_key = "${var.CONSUL_ENCRYPT_KEY}"
  consul_master_token = "${var.CONSUL_MASTER_TOKEN}"

  cluster_vm_count = "${var.CONSUL_SERVER_CLUSTER_VM_COUNT}"
  cluster_vm_size = "${var.CONSUL_SERVER_CLUSTER_VM_SIZE}"
  cluster_vm_image_reference = "${var.HASHI_MANAGED_VM_IMAGE_NAME}"

  admin_user_name = "${var.ADMIN_NAME}"
  ssh_public_key = "${var.SSH_PUBLIC_KEY}"

  vnet_name = "${azurerm_virtual_network.hashicluster.name}"
  vnet_resource_group_name = "${azurerm_resource_group.hashicluster.name}"
  subnet_prefix = "${local.consul_server_subnet_suffix}"
}

module "vault_servers" {
  source = "./modules/hashicluster"
  
  hashiapp = "vault"
  cluster_name = "${local.vault_cluster_name}"
  resource_group_name = "${local.vault_cluster_name}"
  resource_group_location = "${azurerm_resource_group.hashicluster.location}"  

  consul_vmss_name = "${module.consul_servers.cluster_name}"
  consul_vmss_rg = "${module.consul_servers.cluster_resource_group_name}"
  consul_encrypt_key = "${module.consul_servers.consul_encrypt_key}"
  consul_master_token = "${module.consul_servers.consul_master_token}"

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
  subnet_prefix = "${local.vault_server_subnet_suffix}"
}

module "nomad_servers" {
  source = "./modules/hashicluster"
  
  hashiapp = "nomad"
  cluster_name = "${local.nomad_cluster_name}"
  resource_group_name = "${local.nomad_cluster_name}"
  resource_group_location = "${azurerm_resource_group.hashicluster.location}"  

  consul_vmss_name = "${module.consul_servers.cluster_name}"
  consul_vmss_rg = "${module.consul_servers.cluster_resource_group_name}"
  consul_encrypt_key = "${module.consul_servers.consul_encrypt_key}"

  cluster_vm_count = "3"
  cluster_vm_size = "${var.CONSUL_SERVER_CLUSTER_VM_SIZE}"
  cluster_vm_image_reference = "${var.HASHI_MANAGED_VM_IMAGE_NAME}"

  nomad_encrypt_key = "${var.NOMAD_ENCRYPT_KEY}"

  admin_user_name = "${var.ADMIN_NAME}"
  ssh_public_key = "${var.SSH_PUBLIC_KEY}"

  vnet_name = "${azurerm_virtual_network.hashicluster.name}"
  vnet_resource_group_name = "${azurerm_resource_group.hashicluster.name}"
  subnet_prefix = "${local.nomad_server_subnet_suffix}"
}

module "worker_nodes" {
  source = "./modules/hashicluster"
  
  hashiapp = "workernode"
  cluster_name = "${local.worker_cluster_name}"
  resource_group_name = "${local.worker_cluster_name}"
  resource_group_location = "${azurerm_resource_group.hashicluster.location}"  

  consul_vmss_name = "${module.consul_servers.cluster_name}"
  consul_vmss_rg = "${module.consul_servers.cluster_resource_group_name}"
  consul_encrypt_key = "${module.consul_servers.consul_encrypt_key}"

  cluster_vm_count = "3"
  cluster_vm_size = "${var.CONSUL_SERVER_CLUSTER_VM_SIZE}"
  cluster_vm_image_reference = "${var.HASHI_MANAGED_VM_IMAGE_NAME}"

  admin_user_name = "${var.ADMIN_NAME}"
  ssh_public_key = "${var.SSH_PUBLIC_KEY}"

  vnet_name = "${azurerm_virtual_network.hashicluster.name}"
  vnet_resource_group_name = "${azurerm_resource_group.hashicluster.name}"
  subnet_prefix = "${local.worker_nodes_subnet_suffix}"
}