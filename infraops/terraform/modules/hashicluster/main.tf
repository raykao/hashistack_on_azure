terraform {
  required_version = ">= 0.11.11"
}

provider "azuread" {
  version = "=0.1.0"
}


data "template_file" "consul" {
  template = "${file("${path.module}/scripts/consul/config_consul_server.sh")}"
  vars = {
    subscription_id = "${data.azurerm_subscription.primary.id}"
        
    consul_vmss_name = "${var.consul_vmss_name}"
    consul_vmss_rg = "${var.consul_vmss_rg}"
    consul_encrypt = "${local.consul_encrypt}"

    consul_server = "${local.consul_server}"
    vault_server = "${local.vault_server}"
    nomad_server = "${local.nomad_server}"
  }
}

locals {
  consul_encrypt = "${var.consul_encrypt ? var.consul_encrypt : base64encode(string)}"
  cluster_name = "${var.hashiapp != "consul" && var.hashiapp == "consul" ? "true" : ""}"
  consul_server = "${var.cluster_type != "worker" && var.hashiapp == "consul" ? "true" : ""}"
  vault_server = "${var.cluster_type  !="worker" && var.hashiapp == "vault" ? "true" : ""}" 
  nomad_server = "${var.cluster_type  !="worker" && var.hashiapp == "nomad" ? "true" : ""}" 
  

}


resource "azurerm_virtual_machine_scale_set" "hashicluster" {
  name = "${var.cluster_name}"
  resource_group_name = "${var.resource_group_name}"
  location = "${var.resource_group_location}"
  upgrade_policy_mode = "Manual"

  sku {
    name = "${var.cluster_vm_size}"
    tier = "Standard"
    capacity = "${var.cluster_vm_count}"
  }

  identity = {
    type = "UserAssigned"
    identity_ids = ["${var.msi_id}"]
  }

  os_profile {
    computer_name_prefix = "hashi${var.hashiapp}"
    admin_username = "${var.admin_user_name}"
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
      subnet_id = "${var.subnet_id}"
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
    scaleSetName = "${var.cluster_name}"
  }
}
