terraform {
  required_version = ">= 0.11.11"
}

data "azurerm_subscription" "primary" {}

data "azurerm_client_config" "current" {}


resource "random_string" "consul_encrypt" {
  length = 16
  special = false
}
resource "random_string" "nomad_encrypt" {
  length = 16
  special = false
}

resource "random_uuid" "consul_master_token" {

}

resource "random_string" "msi_name" {
  length = 8
  number = false
  special = false
}


resource "random_pet" "keyvault" {
  prefix = "hashi"
}

resource "random_string" "azure_key_vault_shamir_key_name" {
  length = 16
  special = false
}


locals {
  consul_encrypt_key              = "${var.consul_encrypt_key != "" ? var.consul_encrypt_key : base64encode(random_string.consul_encrypt.result)}"
  consul_master_token               = "${var.consul_master_token != "" ? var.consul_master_token : random_uuid.consul_master_token.result}"
  azure_key_vault_shamir_key_name = "${var.azure_key_vault_shamir_key_name != "" ? var.azure_key_vault_shamir_key_name : random_string.azure_key_vault_shamir_key_name.result}"
  azure_key_vault_name            = "${var.azure_key_vault_name != "" ? var.azure_key_vault_name : random_pet.keyvault.id}"
  key_vault_count                 = "${var.hashiapp == "vault" ? 1 : 0}"
  vault_service_endpoints         = "${var.hashiapp == "vault" ? "Microsoft.KeyVault" : ""}"
  nomad_encrypt_key              = "${var.nomad_encrypt_key != "" ? var.nomad_encrypt_key : base64encode(random_string.nomad_encrypt.result)}"
}

data "template_file" "hashiconfig" {
  template = "${file("${path.module}/scripts/config_hashiapps.sh")}"
  vars = {
    is_server = "${var.hashiapp}"
    cluster_vm_count = "${var.cluster_vm_count}"
    azure_subscription_id = "${data.azurerm_subscription.primary.id}"
    azure_tenant_id = "${data.azurerm_client_config.current.tenant_id}"
    
    consul_vmss_name = "${var.consul_vmss_name}"
    consul_vmss_rg = "${var.consul_vmss_rg}"
    consul_dc_name = "${var.consul_dc_name}"
    consul_encrypt_key = "${local.consul_encrypt_key}"
    consul_master_token = "${local.consul_master_token}"

    azure_key_vault_name = "${local.azure_key_vault_name}"
    azure_key_vault_shamir_key_name = "${local.azure_key_vault_shamir_key_name}"
    
    vault_key_shares = "${var.vault_key_shares}"
    vault_key_threshold = "${var.vault_key_threshold}"
    vault_pgp_keys = "${var.vault_pgp_keys}"

    nomad_encrypt_key = "${local.nomad_encrypt_key}"
    
    admin_user_name = "${var.admin_user_name}"
  }
}

resource "azurerm_resource_group" "hashicluster" {
  name     = "${var.resource_group_name}"
  location = "${var.resource_group_location}"
  tags = {
      hashiapp = "${var.hashiapp}"
    }
}

resource "azurerm_key_vault" "hashicluster" {
  count                       = "${local.key_vault_count}"
  name                        = "${local.azure_key_vault_name}"
  location                    = "${azurerm_resource_group.hashicluster.location}"
  resource_group_name         = "${azurerm_resource_group.hashicluster.name}"
  enabled_for_deployment      = true
  enabled_for_disk_encryption = true
  tenant_id                   = "${data.azurerm_client_config.current.tenant_id}"

  sku {
    name = "standard"
  }
  
  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
    virtual_network_subnet_ids = ["${azurerm_subnet.hashicluster.id}"]
  }
}

resource "azurerm_key_vault_access_policy" "terraform_serviceprincipal" {
  count       = "${local.key_vault_count}"
  key_vault_id = "${element(azurerm_key_vault.hashicluster.*.id, 0)}"
  # vault_name = "${element(azurerm_key_vault.hashicluster.*.name, 0)}"
  # resource_group_name = "${element(azurerm_key_vault.hashicluster.*.resource_group_name, 0)}"

  tenant_id = "${data.azurerm_client_config.current.tenant_id}"
  object_id = "${data.azurerm_client_config.current.service_principal_object_id}"

  key_permissions = [
    "get",
    "list",
    "create",
    "delete",
    "update",
    "wrapKey",
    "unwrapKey",
  ]
}

resource "azurerm_key_vault_access_policy" "vault_cluster" {
  count       = "${local.key_vault_count}"
  key_vault_id = "${element(azurerm_key_vault.hashicluster.*.id, 0)}"
  # vault_name = "${element(azurerm_key_vault.hashicluster.*.name, 0)}"
  # resource_group_name = "${element(azurerm_key_vault.hashicluster.*.resource_group_name, 0)}"

  tenant_id = "${data.azurerm_client_config.current.tenant_id}"
  object_id = "${azurerm_user_assigned_identity.hashiapp_msi.principal_id}"

  key_permissions = [
    "get",
    "list",
    "create",
    "delete",
    "update",
    "wrapKey",
    "unwrapKey",
  ]
}

resource "azurerm_key_vault_key" "generated" {
  # Ensure the policies are in place before trying to create the key to store auto-unseal keys
  depends_on = ["azurerm_key_vault_access_policy.terraform_serviceprincipal", "azurerm_subnet.hashicluster"]
  count     = "${local.key_vault_count}"
  name      = "${local.azure_key_vault_shamir_key_name}"
  key_vault_id = "${element(azurerm_key_vault.hashicluster.*.id, 0)}"
  key_type  = "RSA"
  key_size  = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
}


resource "azurerm_subnet" "hashicluster" {
  name           = "${var.cluster_name}-subnet"
  virtual_network_name = "${var.vnet_name}"
  resource_group_name  = "${var.vnet_resource_group_name}"
  address_prefix = "${var.subnet_prefix}"
  service_endpoints = ["${local.vault_service_endpoints}"]
}


resource "azurerm_user_assigned_identity" "hashiapp_msi" {
  resource_group_name = "${azurerm_resource_group.hashicluster.name}"
  location            = "${azurerm_resource_group.hashicluster.location}"

  name = "${var.hashiapp}-${random_string.msi_name.result}-msi"

  tags = {
    hashi = "vmssreader"
  }
}

resource "azurerm_role_assignment" "test" {
  scope                = "${data.azurerm_subscription.primary.id}"
  role_definition_name = "Reader"
  principal_id         = "${azurerm_user_assigned_identity.hashiapp_msi.principal_id}"
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
    identity_ids = ["${azurerm_user_assigned_identity.hashiapp_msi.id}"]
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