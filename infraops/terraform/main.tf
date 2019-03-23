terraform {
  required_version = ">= 0.11.11"
  backend "azurerm" {
  }
}

provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version = "=1.21.0"
}

resource "azurerm_resource_group" "consul_servers" {
  name     = "consul-servers"
  location = "${var.AZURE_DC_LOCATION}"
}


resource "azurerm_resource_group" "vault_servers" {
  name     = "vault-servers"
  location = "${var.AZURE_DC_LOCATION}"
}

resource "azurerm_resource_group" "nomad_servers" {
  name     = "nomad-servers"
  location = "${var.AZURE_DC_LOCATION}"
}

resource "azurerm_resource_group" "hashi_cluster" {
  name     = "hashi-cluster"
  location = "${var.AZURE_DC_LOCATION}"
}

module "consul_servers" {
  source = "./modules/hashi-cluster"
  vm_size = "Standard_D2_v3"
  resource_group = "${azurerm_resource_group.consul_servers.name}"
  location = "${azurerm_resource_group.consul_servers.location}"
  cluster_size = 3
}

module "vault_servers" {
  source = "./modules/hashi-cluster"
  vm_size = "Standard_D2_v3"
  resource_group = "${azurerm_resource_group.vault_servers.name}"
  location = "${azurerm_resource_group.vault_servers.location}"
  cluster_size = 3
}

module "nomad_servers" {
  source = "./modules/hashi-cluster"
  vm_size = "Standard_D2_v3"
  resource_group = "${azurerm_resource_group.nomad_servers.name}"
  location = "${azurerm_resource_group.nomad_servers.location}"
  cluster_size = 3
}

module "hashi_cluster" {
  source = "./modules/hashi-cluster"
  vm_size = "Standard_D2_v3"
  resource_group = "${azurerm_resource_group.hashi_cluster.name}"
  location = "${azurerm_resource_group.hashi_cluster.location}"
  cluster_size = 10
}