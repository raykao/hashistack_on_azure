resource "random_string" "suffix" {
  length = 8
  special = false
  number = false
}

locals {
  suffix = "${var.suffix != "" ? var.suffix : random_string.suffix.result}"
  jumpboxname = "jumpbox-${var.suffix}"
}


resource "azurerm_resource_group" "jumpbox_server" {
  name = "${local.jumpboxname}-server"
  location = "${var.resource_group_location}"
}

resource "azurerm_subnet" "jumpbox_server" {
  name           = "${local.jumpboxname}-subnet"
  virtual_network_name = "${var.virtual_network_name}"
  resource_group_name  = "${var.virtual_network_resource_group_name}"
  address_prefix = "${var.subnet_prefix}"
}

resource "azurerm_public_ip" "jumpbox_server" {
  name                = "${local.jumpboxname}-pip"
  location            = "${azurerm_resource_group.jumpbox_server.location}"
  resource_group_name = "${azurerm_resource_group.jumpbox_server.name}"
  allocation_method   = "Dynamic"
  idle_timeout_in_minutes = 30
  domain_name_label = "${local.jumpboxname}"
}

resource "azurerm_network_interface" "jumpbox_server" {
  name                = "${local.jumpboxname}-nic"
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
  name                  = "${local.jumpboxname}"
  location              = "${azurerm_resource_group.jumpbox_server.location}"
  resource_group_name   = "${azurerm_resource_group.jumpbox_server.name}"
  network_interface_ids = ["${azurerm_network_interface.jumpbox_server.id}"]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    id   = "${var.managed_disk_id}"

  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "${local.jumpboxname}"
    admin_username = "${var.admin_name}"
  }
  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys = {
      path = "/home/${var.admin_name}/.ssh/authorized_keys"
      key_data = "${var.ssh_key}"
    }
  }
}