variable "cluster_vm_image_reference" {
  
}

variable "ssh_public_key" {
  
}


variable "subnet_id" {
  
}

variable "associate_public_ip_address_load_balancer" {
  default = false
}

variable "cluster_name" {
  default = "hashiworkercluster"
}

variable "cluster_type" {
  default = ""
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
  
}

variable "consul_encrypt_key" {
  default = ""
}

variable "consul_dc_name" {
  default = "dc1"
}

variable "consul_vmss_name" {
  
}


variable "consul_vmss_rg" {
  
}



