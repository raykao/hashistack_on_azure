variable "CLUSTER_ENVIRONMENT" {
  default = "test"
}

variable "AZURE_RESOURCE_GROUP_NAME" {
  default = "hashi-cluster"
}

variable "AZURE_DC_LOCATION" {
  default = "Canada Central"
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
  
}

variable "ADMIN_NAME" {
  default = "hashiadmin"
}

variable "SSH_PUBLIC_KEY" {
  
}

variable "CONSUL_ENCRYPT_KEY" {
  default = ""
}

variable "CONSUL_VMSS_NAME" {
  
}

variable "CONSUL_VMSS_RG" {
  
}


