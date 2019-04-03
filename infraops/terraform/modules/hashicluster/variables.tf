
variable "hashiapp" {
  default = "workernode"
}

variable "cluster_name" {
  default = "workernode"
}

variable "resource_group_name" {
  
}


variable "resource_group_location" {
  
}

variable "consul_vmss_name" {
  description = "Required - cluster needs the Azure VMSS Name and Resource group of the Consul Server Cluster. You can query the Outputs for 'consul_vmss_name' to get the value."
}

variable "consul_vmss_rg" {
  description = "Required - cluster needs the Azure VMSS Name and Resource group of the Consul Server Cluster. You can query the Outputs for 'consul_vmss_rg' to get the value."
}

variable "consul_encrypt_key" {
  description = "Optional - Supply the initial Consul Gossip Encryption Key or one will be auto generated to bootstrap the cluster.  You can query the Outputs for 'consul_encrypt_key' to get the value."
  default = ""
}


variable "consul_dc_name" {
  description = "The name of the Consul DC being deployed."
  default = "dc1"
}

variable "vault_generated_key_name" {
  description = "The auto unseal key name stored in Azure Key Vault"
  default = ""
}

variable "vault_azure_key_vault_name" {
  description = "Required - The Azure Key Vault Name to get the Auto Unseal Key from."
}



variable "associate_public_ip_address_load_balancer" {
  description = "Should a load balancer be deployed? Default: Nope."
  default = false
}


variable "cluster_vm_count" {
  default = 3
}

variable "cluster_vm_size" {
  default = "Standard_D2s_v3"
}

variable "cluster_vm_image_reference" {
  description = "The Managed Image reference URI."
}

variable "admin_user_name" {
  default = "hashiadmin"
}

variable "ssh_public_key" {
  description = "The SSH key to install for the default system admin."
}

variable "vnet_name" {
  description = "Required - needed to join a network - will not bootstrap one."
}

variable "vnet_resource_group_name" {
  description = "Required - need to create subnet"
}


variable "subnet_prefix" {
  description = "Required - subnet address space"
}
