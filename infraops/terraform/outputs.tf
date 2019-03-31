output "consul_encrypt_key" {
  value = "${module.consul_servers.consul_encrypt_key}"
}

output "consul_reader_msi" {
  value = "${azurerm_user_assigned_identity.consul-vmss-reader.*.id}"
}