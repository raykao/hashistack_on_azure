variable "CLUSTER_ENVIRONMENT" {
  default = "test"
}

variable "AZURE_RESOURCE_GROUP_NAME" {
  default = "hashicluster"
}

variable "AZURE_DC_LOCATION" {
  default = "Canada Central"
}

variable "CONSUL_VMSS_NAME" {
  default = "consul-server"
}

variable "CONSUL_VMSS_RG" {
  default = "consul-server"
}


variable "CONSUL_SERVER_CLUSTER_VM_COUNT" {
  default = 3
}

variable "CONSUL_SERVER_CLUSTER_VM_SIZE" {
  default = "Standard_D2s_v3"
}

variable "HASHI_MANAGED_VM_IMAGE_NAME" {
  
}

variable "MSI_ID" {
  default = ""
}

variable "ADMIN_NAME" {
  default = "hashiadmin"
}

variable "SSH_PUBLIC_KEY" {
  description = "Required - needed to log into server"
}

variable "CONSUL_ENCRYPT_KEY" {
  default = ""
}

