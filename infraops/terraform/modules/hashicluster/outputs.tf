output "consul_vmss_name" {
  value = "${var.consul_vmss_name}"
}

output "consul_vmss_rg" {
  value = "${var.consul_vmss_rg}"
}

output "consul_encrypt_key" {
  description = "Consul Gossip Encryption Key"
  value = "${local.consul_encrypt_key}"
}

output "consul_master_token" {
  description = "Consul Master ACL Token"
  value = "${var.hashiapp == "consul" ? local.consul_master_token : ""}"
}


output "msi_principal_id" {
  value = "${azurerm_user_assigned_identity.hashiapp_msi.principal_id}"
}

output "subnet_id" {
  value = "${azurerm_subnet.hashicluster.id}"
}

output "cluster_name" {
  value = "${azurerm_virtual_machine_scale_set.hashicluster.name}"
}

output "cluster_resource_group_name" {
  value = "${azurerm_resource_group.hashicluster.name}"
}

output "nomad_encrypt_key" {
  value = "${var.hashiapp == "nomad" ? local.nomad_encrypt_key : ""}"
}



