terraform {
  required_version = ">= 0.11.11"
}

provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version = "=1.21.0"
}

data "azurerm_subscription" "primary" {}

locals {
  prefix = "${random_string.prefix.result}"
}

resource "random_string" "prefix" {
  length = 8
  special = false
  upper = false
  lower = true
}


resource "azurerm_resource_group" "hashi_cluster" {
  name     = "hashicluster-shared"
  location = "${var.AZURE_DC_LOCATION}"
}

resource "azurerm_resource_group" "consul_servers" {
  name     = "consul-servers"
  location = "${var.AZURE_DC_LOCATION}"
  tags = {
      hashi = "consul"
    }
}

resource "azurerm_resource_group" "vault_servers" {
  name     = "vault-servers"
  location = "${var.AZURE_DC_LOCATION}"
  tags = {
      hashi = "vault"
    }
}

resource "azurerm_resource_group" "nomad_servers" {
  name     = "nomad-servers"
  location = "${var.AZURE_DC_LOCATION}"
  tags = {
      hashi = "nomad"
    }
}

resource "azurerm_resource_group" "hashiworker_general_cluster001" {
  name     = "hashiworker-general-001"
  location = "${var.AZURE_DC_LOCATION}"
  tags = {
    hashi = "worker"
  }
}

resource "azurerm_resource_group" "jumpbox-server" {
  name = "jumpbox-servers"
  location = "${var.AZURE_DC_LOCATION}"
  tags = {
    hashi = "jumpbox-server"
  }
}

resource "azurerm_user_assigned_identity" "consul-vmss-reader" {
  count = "${var.MSI_ID == "" ? 1 : 0}"
  resource_group_name = "${azurerm_resource_group.hashi_cluster.name}"
  location            = "${azurerm_resource_group.hashi_cluster.location}"

  name = "consul-vmss-reader"

  tags = {
    hashi = "vmssreader"
  }
}

resource "azurerm_role_assignment" "test" {
  count = "${var.MSI_ID == "" ? 1 : 0}"
  scope                = "${data.azurerm_subscription.primary.id}"
  role_definition_name = "Reader"
  principal_id         = "${azurerm_user_assigned_identity.consul-vmss-reader.principal_id}"
  
  tags = {
    hashi = "vmssreader"
  }
}



resource "azurerm_virtual_network" "hashi_net" {
  name                = "hashinetwork"
  location            = "${azurerm_resource_group.hashi_cluster.location}"
  resource_group_name = "${azurerm_resource_group.hashi_cluster.name}"
  address_space       = ["10.0.0.0/8"]

  tags = {
    environment = "${var.CLUSTER_ENVIRONMENT}"
  }
}

resource "azurerm_subnet" "consul-server-subnet" {
  name           = "${azurerm_resource_group.consul_servers.name}-subnet"
  resource_group_name  = "${azurerm_resource_group.hashi_cluster.name}"
  virtual_network_name = "${azurerm_virtual_network.hashi_net.name}"
  address_prefix = "10.0.0.0/28"
}

resource "azurerm_subnet" "vault-server-subnet" {
  name           = "${azurerm_resource_group.vault_servers.name}-subnet"
  resource_group_name  = "${azurerm_resource_group.hashi_cluster.name}"
  virtual_network_name = "${azurerm_virtual_network.hashi_net.name}"
  address_prefix = "10.0.0.16/28"
}

resource "azurerm_subnet" "nomad-server-subnet" {
  name           = "${azurerm_resource_group.nomad_servers.name}-subnet"
  resource_group_name  = "${azurerm_resource_group.hashi_cluster.name}"
  virtual_network_name = "${azurerm_virtual_network.hashi_net.name}"
  address_prefix = "10.0.0.32/28"
}

resource "azurerm_subnet" "jumpbox-subnet" {
  name           = "${azurerm_resource_group.jumpbox-server.name}-subnet"
  resource_group_name  = "${azurerm_resource_group.hashi_cluster.name}"
  virtual_network_name = "${azurerm_virtual_network.hashi_net.name}"
  address_prefix = "10.0.0.48/29"
}


resource "azurerm_subnet" "hashiworker_general_cluster001-subnet" {
  name           = "${azurerm_resource_group.hashiworker_general_cluster001.name}-subnet"
  resource_group_name  = "${azurerm_resource_group.hashi_cluster.name}"
  virtual_network_name = "${azurerm_virtual_network.hashi_net.name}"
  address_prefix = "10.1.0.0/17"
}

resource "azurerm_public_ip" "jumpbox-server" {
  name                = "jumpbox-pip"
  location            = "${azurerm_resource_group.jumpbox-server.location}"
  resource_group_name = "${azurerm_resource_group.jumpbox-server.name}"
  allocation_method   = "Dynamic"
  idle_timeout_in_minutes = 30
  domain_name_label = "${local.prefix}"

  tags = {
    environment = "${var.CLUSTER_ENVIRONMENT}"
  }
}

resource "azurerm_network_interface" "jumpbox-server" {
  name                = "jumpbox-nic"
  location            = "${azurerm_resource_group.jumpbox-server.location}"
  resource_group_name = "${azurerm_resource_group.jumpbox-server.name}"

  ip_configuration {
    name                          = "jumpboxconfiguration"
    subnet_id                     = "${azurerm_subnet.jumpbox-subnet.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.jumpbox-server.id}"
  }
}

resource "azurerm_virtual_machine" "jumpbox-server" {
  name                  = "jumpboxvm"
  location              = "${azurerm_resource_group.jumpbox-server.location}"
  resource_group_name   = "${azurerm_resource_group.jumpbox-server.name}"
  network_interface_ids = ["${azurerm_network_interface.jumpbox-server.id}"]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "jumpbox001"
    admin_username = "${var.ADMIN_NAME}"
  }
  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys = {
      path = "/home/${var.ADMIN_NAME}/.ssh/authorized_keys"
      key_data = "${var.SSH_PUBLIC_KEY}"
    }
  }
  tags = {
    environment = "${var.CLUSTER_ENVIRONMENT}"
  }
}

module "consul_servers" {
  source = "./modules/hashicluster"
  
  hashiapp = "consul"
  cluster_name = "${var.CONSUL_VMSS_NAME}"
  
  consul_vmss_name = "${var.CONSUL_VMSS_NAME}"
  consul_vmss_rg = "${azurerm_resource_group.consul_servers.name}"
  consul_encrypt_key = "${var.CONSUL_ENCRYPT_KEY}"

  msi_id = "${azurerm_user_assigned_identity.consul-vmss-reader.id}"
  cluster_vm_count = "${var.CONSUL_SERVER_CLUSTER_VM_COUNT}"
  cluster_vm_size = "${var.CONSUL_SERVER_CLUSTER_VM_SIZE}"
  cluster_vm_image_reference = "${var.HASHI_MANAGED_VM_IMAGE_NAME}"

  resource_group_name = "${azurerm_resource_group.consul_servers.name}"
  resource_group_location = "${azurerm_resource_group.consul_servers.location}"
  
  admin_user_name = "${var.ADMIN_NAME}"
  ssh_public_key = "${var.SSH_PUBLIC_KEY}"

  subnet_id = "${azurerm_subnet.consul-server-subnet.id}"
}

# module "vault_servers" {
#   source = "./modules/hashi-cluster"
#   vm_size = "Standard_D2_v3"
#   resource_group = "${azurerm_resource_group.vault_servers.name}"
#   location = "${azurerm_resource_group.vault_servers.location}"
#   cluster_name = "${azurerm_resource_group.vault_servers.name}"
#   cluster_vm_count = "${var.VAULT_SERVER_CLUSTER_INSTANCE_COUNT}"
#   cluster_vm_size = "${var.VAULT_VM_SERVER_SIZE}"
#   cluster_type = "server"
#   vm_image = "${var.HASHI_MANAGED_VM_IMAGE_NAME}"
#   hashiapp = "vault"
# }

# module "nomad_servers" {
#   source = "./modules/hashi-cluster"
#   vm_size = "Standard_D2_v3"
#   resource_group = "${azurerm_resource_group.nomad_servers.name}"
#   location = "${azurerm_resource_group.nomad_servers.location}"
#   cluster_name = "${azurerm_resource_group.nomad_servers.name}"
#   cluster_vm_count = "${var.NOMAD_SERVER_CLUSTER_INSTANCE_COUNT}"
#   cluster_vm_size = "${var.VAULT_VM_SERVER_SIZE}"
#   cluster_type = "server"
#   vm_image = "${var.HASHI_MANAGED_VM_IMAGE_NAME}"
#   hashiapp = "nomad"
# }

# module "hashi_worker_general_cluster001" {
#   source = "./modules/hashi-cluster"
#   vm_size = "Standard_D2_v3"
#   resource_group = "${azurerm_resource_group.hashi_worker_general_cluster001.name}"
#   location = "${azurerm_resource_group.hashi_worker_general_cluster001.location}"
#   cluster_name = "wc001"
#   cluster_vm_count = 10
#   cluster_vm_size = "${var.VAULT_VM_SERVER_SIZE}"
#   cluster_type = "worker"
#   vm_image = "${var.HASHI_MANAGED_VM_IMAGE_NAME}"
#   hashiapp = "worker"
# }