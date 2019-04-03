terraform {
  required_version = ">= 0.11.11"
}

data "azurerm_subscription" "primary" {}


resource "random_string" "consul_encrypt" {
  length = 16
  special = false
}

resource "random_string" "msi_name" {
  length = 8
  number = false
  special = false
}

locals {
  auto_generate_key = "${base64encode(random_string.consul_encrypt.result)}"
  consul_encrypt_key = "${var.consul_encrypt_key != "" ? var.consul_encrypt_key : local.auto_generate_key}"
}


data "template_file" "hashiconfig" {
  template = "${file("${path.module}/scripts/consul/config_hashiapps.sh")}"
  vars = {
    is_server = "${var.hashiapp}"    
    azure_subscription_id = "${data.azurerm_subscription.primary.id}"
    consul_vmss_name = "${var.consul_vmss_name}"
    consul_vmss_rg = "${var.consul_vmss_rg}"
    consul_dc_name = "${var.consul_dc_name}"
    consul_encrypt_key = "${local.consul_encrypt_key}"
  }
}

resource "azurerm_resource_group" "hashicluster" {
  name     = "${var.resource_group_name}"
  location = "${var.resource_group_location}"
  tags = {
      hashiapp = "${var.hashiapp}"
    }
}

resource "azurerm_subnet" "hashicluster" {
  name           = "${var.cluster_name}-subnet"
  virtual_network_name = "${var.vnet_name}"
  resource_group_name  = "${var.vnet_resource_group_name}"
  address_prefix = "${var.subnet_prefix}"
}


resource "azurerm_user_assigned_identity" "consul-vmss-reader" {
  resource_group_name = "${azurerm_resource_group.hashicluster.name}"
  location            = "${azurerm_resource_group.hashicluster.location}"

  name = "${var.hashiapp}-${random_string.msi_name.result}-msi"

  tags = {
    hashi = "vmssreader"
  }
}

resource "azurerm_virtual_machine_scale_set" "hashicluster" {
  name = "${var.cluster_name}"
  resource_group_name = "${azurerm_resource_group.hashicluster.name}"
  location = "${azurerm_resource_group.hashicluster.location}"
  upgrade_policy_mode = "Manual"

  sku {
    capacity = "${var.cluster_vm_count}"
    name = "${var.cluster_vm_size}"
    tier = "Standard"
  }

  identity = {
    type = "UserAssigned"
    identity_ids = ["${azurerm_user_assigned_identity.consul-vmss-reader.id}"]
  }

  os_profile {
    computer_name_prefix = "hashi${var.hashiapp}"
    admin_username = "${var.admin_user_name}"
    custom_data = "${data.template_file.hashiconfig.rendered}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path = "/home/${var.admin_user_name}/.ssh/authorized_keys"
      key_data = "${var.ssh_public_key}"
    }
  }

  network_profile {
    name = "HashiClusterNetworkProfile"
    primary = true

    ip_configuration {
      primary = true
      name = "HashiClusterIPConfiguration"
      subnet_id = "${azurerm_subnet.hashicluster.id}"
    }
  }

  storage_profile_image_reference {
    id = "${var.cluster_vm_image_reference}"
  }

  storage_profile_os_disk {
    name = ""
    caching = "ReadWrite"
    create_option = "FromImage"
    os_type = "Linux"
    managed_disk_type = "Standard_LRS"
  }

  tags {
    scaleSetName = "${var.hashiapp}"
  }
}
