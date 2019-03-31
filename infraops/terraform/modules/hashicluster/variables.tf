variable "azure_subscription_id" {
  default = ""
  description = "Azure subscription to deploy into"
}


variable "cluster_vm_image_reference" {
  description = "The Managed Image reference URI."
}

variable "ssh_public_key" {
  description = "The SSH key to install for the default system admin."
}


variable "subnet_id" {
  description = "The subnet to deploy the cluster into."
}

variable "associate_public_ip_address_load_balancer" {
  description = "Should a load balancer be deployed? Default: Nope."
  default = false
}

variable "cluster_name" {
  default = "hashiworkercluster"
}

variable "cluster_vm_size" {
  default = "Standard_D2s_v3"
}

variable "cluster_vm_count" {
  default = 3
}

variable "hashiapp" {
  default = ""
}

variable "admin_user_name" {
  default = "hashiadmin"
}

variable "resource_group_name" {
  
}

variable "resource_group_location" {
  
}

variable "msi_id" {
  description = "Required - This is the Azure Managed Service Identity that will be associated with the cluster to read the IP addresses of the Consul Servers with their VMSS Name and RG values. You can query the Outputs for 'msi_id' to get the value."
}

variable "consul_encrypt_key" {
  description = "Optional - Supply the initial Consul Gossip Encryption Key or one will be auto generated to bootstrap the cluster.  You can query the Outputs for 'consul_encrypt_key' to get the value."
  default = ""
}

variable "consul_dc_name" {
  description = "The name of the Consul DC being deployed."
  default = "dc1"
}

variable "consul_vmss_name" {
  description = "Required - cluster needs the Azure VMSS Name and Resource group of the Consul Server Cluster. You can query the Outputs for 'consul_vmss_name' to get the value."
}


variable "consul_vmss_rg" {
  description = "Required - cluster needs the Azure VMSS Name and Resource group of the Consul Server Cluster. You can query the Outputs for 'consul_vmss_rg' to get the value."
}



