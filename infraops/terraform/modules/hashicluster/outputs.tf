output "consul_vmss_name" {
  value = "${var.consul_vmss_name}"
}

output "consul_vmss_rg" {
  value = "${var.consul_vmss_rg}"
}

output "consul_encrypt_key" {
  value = "${local.consul_encrypt_key}"
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


