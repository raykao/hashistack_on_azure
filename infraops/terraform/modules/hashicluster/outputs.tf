output "consul_vmss_name" {
  value = "${var.consul_vmss_name}"
}

output "consul_vmss_rg" {
  value = "${var.consul_vmss_rg}"
}

output "consul_encrypt_key" {
  value = "${local.consul_encrypt_key}"
}