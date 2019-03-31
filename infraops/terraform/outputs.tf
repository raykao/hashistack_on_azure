output "consul_encrypt" {
  value = "${local.consul_encrypt}"
}

output "consul_reader_msi" {
  value = "${azurerm_user_assigned_identity.consul-vmss-reader.*.id}"
}