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
  default = "worker"
}

variable "cluster_vm_size" {
  default = "Standard_D2s_v3"
}

variable "cluster_vm_count" {
  default = 3
}

variable "hashiapp" {
  default = "worker"
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

