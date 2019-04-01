output "consul_encrypt_key" {
  value = "${module.consul_servers.consul_encrypt_key}"
}

output "consul_vmss_name" {
  value = "${module.consul_servers.consul_vmss_name}"
}

output "consul_vmss_rg" {
  value = "${module.consul_servers.consul_vmss_rg}"
}

output "jumpbox_dns" {
  value = "${azurerm_public_ip.jumpbox_server.fqdn}"
}