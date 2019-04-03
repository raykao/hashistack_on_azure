terraform {
  required_version = ">= 0.11.11"
}

provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version = "=1.23.0"
}

locals {
  dns_name = "${random_pet.dns_name.id}"
}

data "azurerm_client_config" "current" {}


resource "random_pet" "dns_name" {
  separator = "-"
}


resource "azurerm_resource_group" "hashicluster" {
  name     = "hashicluster"
  location = "${var.AZURE_DC_LOCATION}"
}

resource "azurerm_key_vault" "hashicluster" {
  name                        = "keyvault-${local.dns_name}"
  location                    = "${azurerm_resource_group.hashicluster.location}"
  resource_group_name         = "${azurerm_resource_group.hashicluster.name}"
  tenant_id                   = "${data.azurerm_client_config.current.tenant_id}"

  sku {
    name = "standard"
  }

  tags = {
    environment = "Production"
  }
}


resource "azurerm_virtual_network" "hashinet" {
  name                = "hashinetwork"
  location            = "${azurerm_resource_group.hashicluster.location}"
  resource_group_name = "${azurerm_resource_group.hashicluster.name}"
  address_space       = ["10.0.0.0/8"]

  tags = {
    environment = "${var.CLUSTER_ENVIRONMENT}"
  }
}


resource "azurerm_resource_group" "jumpbox_server" {
  name = "jumpbox_servers"
  location = "${azurerm_resource_group.hashicluster.location}"
  tags = {
    hashi = "jumpbox_server"
  }
}

resource "azurerm_public_ip" "jumpbox_server" {
  name                = "jumpbox-pip"
  location            = "${azurerm_resource_group.jumpbox_server.location}"
  resource_group_name = "${azurerm_resource_group.jumpbox_server.name}"
  allocation_method   = "Dynamic"
  idle_timeout_in_minutes = 30
  domain_name_label = "jumpbox-${local.dns_name}"

  tags = {
    environment = "${var.CLUSTER_ENVIRONMENT}"
  }
}

resource "azurerm_subnet" "jumpbox_server" {
  name           = "jumpbox-subnet"
  virtual_network_name = "${azurerm_virtual_network.hashinet.name}"
  resource_group_name  = "${azurerm_resource_group.hashicluster.name}"
  address_prefix = "10.0.0.48/29"
}


resource "azurerm_network_interface" "jumpbox_server" {
  name                = "jumpbox-nic"
  location            = "${azurerm_resource_group.jumpbox_server.location}"
  resource_group_name = "${azurerm_resource_group.jumpbox_server.name}"

  ip_configuration {
    name                          = "jumpboxconfiguration"
    subnet_id                     = "${azurerm_subnet.jumpbox_server.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.jumpbox_server.id}"
  }
}

resource "azurerm_virtual_machine" "jumpbox_server" {
  name                  = "jumpboxvm"
  location              = "${azurerm_resource_group.jumpbox_server.location}"
  resource_group_name   = "${azurerm_resource_group.jumpbox_server.name}"
  network_interface_ids = ["${azurerm_network_interface.jumpbox_server.id}"]
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

  vnet_name = "${azurerm_virtual_network.hashinet.name}"
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

  admin_user_name = "${var.ADMIN_NAME}"
  ssh_public_key = "${var.SSH_PUBLIC_KEY}"

  vnet_name = "${azurerm_virtual_network.hashinet.name}"
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

  cluster_vm_count = "3"
  cluster_vm_size = "${var.CONSUL_SERVER_CLUSTER_VM_SIZE}"
  cluster_vm_image_reference = "${var.HASHI_MANAGED_VM_IMAGE_NAME}"

  admin_user_name = "${var.ADMIN_NAME}"
  ssh_public_key = "${var.SSH_PUBLIC_KEY}"

  vnet_name = "${azurerm_virtual_network.hashinet.name}"
  vnet_resource_group_name = "${azurerm_resource_group.hashicluster.name}"
  subnet_prefix = "10.0.0.32/28"
}

module "worker_servers" {
  source = "./modules/hashicluster"
  
  hashiapp = "workernode"
  cluster_name = "worker-servers"
  resource_group_name = "worker-servers"
  resource_group_location = "${azurerm_resource_group.hashicluster.location}"  

  consul_vmss_name = "${var.CONSUL_VMSS_NAME}"
  consul_vmss_rg = "${var.CONSUL_VMSS_RG}"
  consul_encrypt_key = "${module.consul_servers.consul_encrypt_key}"

  cluster_vm_count = "3"
  cluster_vm_size = "${var.CONSUL_SERVER_CLUSTER_VM_SIZE}"
  cluster_vm_image_reference = "${var.HASHI_MANAGED_VM_IMAGE_NAME}"

  admin_user_name = "${var.ADMIN_NAME}"
  ssh_public_key = "${var.SSH_PUBLIC_KEY}"

  vnet_name = "${azurerm_virtual_network.hashinet.name}"
  vnet_resource_group_name = "${azurerm_resource_group.hashicluster.name}"
  subnet_prefix = "10.1.0.0/17"
}

# Work around to ensure the DNS/FQDN is assigned and available afer the VM is provisioned
# See: https://github.com/terraform-providers/terraform-provider-azurerm/issues/1847#issuecomment-417624630
# data "azurerm_public_ip" "jumpbox_server" {
#   depends_on = ["azurerm_virtual_machine.jumpbox_server"]
#   name = "${azurerm_public_ip.jumpbox_server.name}"
#   resource_group_name = "${azurerm_resource_group.jumpbox_server.name}"
# }

