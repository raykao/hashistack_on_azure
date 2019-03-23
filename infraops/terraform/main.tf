terraform {
  required_version = ">= 0.11.11"
  backend "azurerm" {
  }
}

provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version = "=1.21.0"
}

resource "azurerm_resource_group" "hashi_cluster" {
  name     = "hashi-cluster"
  location = "${var.AZURE_DC_LOCATION}"
}

resource "azurerm_resource_group" "consul_servers" {
  name     = "consul-servers"
  location = "${var.AZURE_DC_LOCATION}"
  tags = {
      hashi = "consul"
      consul = "server"
    }
}


resource "azurerm_resource_group" "vault_servers" {
  name     = "vault-servers"
  location = "${var.AZURE_DC_LOCATION}"
  tags = {
      hashi = "vault"
      vault = "server"
    }
}

resource "azurerm_resource_group" "nomad_servers" {
  name     = "nomad-servers"
  location = "${var.AZURE_DC_LOCATION}"
  tags = {
      hashi = "nomad"
      nomad = "server"
    }
}

resource "azurerm_resource_group" "hashi_worker_general_cluster001" {
  name     = "hashi-worker-general-cluster001"
  location = "${var.AZURE_DC_LOCATION}"
}

resource "azurerm_resource_group" "hashi_bastion_servers" {
  name = "hashi-bastion-servers"
  location = "${var.AZURE_DC_LOCATION}"
}

resource "azurerm_virtual_network" "hashi_net" {
  name                = "hashinetwork"
  location            = "${azurerm_resource_group.hashi_cluster.location}"
  resource_group_name = "${azurerm_resource_group.hashi_cluster.name}"
  address_space       = ["10.0.0.0/8"]

  subnet {
    name           = "${azurerm_resource_group.consul_servers.name}-subnet"
    address_prefix = "10.0.0.0/28"
    tags = {
      hashi = "consul"
      consul = "server"
    }
  }

  subnet {
    name           = "${azurerm_resource_group.vault_servers.name}-subnet"
    address_prefix = "10.0.0.16/28"
    tags = {
      hashi = "vault"
      vault = "server"
    }
  }

  subnet {
    name           = "${azurerm_resource_group.nomad_servers.name}-subnet"
    address_prefix = "10.0.0.32/28"
    tags = {
      hashi = "nomad"
      nomad = "server"
    }
  }

  subnet {
    name           = "${azurerm_resource_group.hashi_bastion_servers.name}"
    address_prefix = "10.0.0.248/29"
  }

  subnet {
    name           = "${azurerm_resource_group.hashi_worker_general_cluster001.name}-subnet"
    address_prefix = "10.1.0.0/23"
    tags = {
      hashi = "cluster001"
      cluster = "001"
      worker = "general"
    }
  }

  tags = {
    environment = "${var.CLUSTER_ENVIRONMENT}"
  }
}

module "consul_servers" {
  source = "./modules/hashi-cluster"
  vm_size = "Standard_D2_v3"
  resource_group = "${azurerm_resource_group.consul_servers.name}"
  location = "${azurerm_resource_group.consul_servers.location}"
  cluster_size = "${var.CONSUL_SERVER_CLUSTER_SIZE}"
  cluster_type = "server"
  vm_image = "${var.HASHI_MANAGED_VM_IMAGE_NAME}"
  hashiapp = "consul"
}

module "vault_servers" {
  source = "./modules/hashi-cluster"
  vm_size = "Standard_D2_v3"
  resource_group = "${azurerm_resource_group.vault_servers.name}"
  location = "${azurerm_resource_group.vault_servers.location}"
  cluster_size = "${var.VAULT_SERVER_CLUSTER_SIZE}"
  cluster_type = "server"
  vm_image = "${var.HASHI_MANAGED_VM_IMAGE_NAME}"
  hashiapp = "vault"
}

module "nomad_servers" {
  source = "./modules/hashi-cluster"
  vm_size = "Standard_D2_v3"
  resource_group = "${azurerm_resource_group.nomad_servers.name}"
  location = "${azurerm_resource_group.nomad_servers.location}"
  cluster_size = "${var.NOMAD_SERVER_CLUSTER_SIZE}"
  cluster_type = "server"
  vm_image = "${var.HASHI_MANAGED_VM_IMAGE_NAME}"
  hashiapp = "nomad"
}

module "hashi_worker_general_cluster001" {
  source = "./modules/hashi-cluster"
  vm_size = "Standard_D2_v3"
  resource_group = "${azurerm_resource_group.hashi_worker_general_cluster001.name}"
  location = "${azurerm_resource_group.hashi_worker_general_cluster001.location}"
  cluster_size = 10
  cluster_type = "worker"
  vm_image = "${var.HASHI_MANAGED_VM_IMAGE_NAME}"
  hashiapp = "worker"
}