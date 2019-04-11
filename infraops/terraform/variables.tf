variable "CLUSTER_ENVIRONMENT" {
  description = "Optional - defaults to 'test'.  Used to tag all the services with the deployment environment type."
  default = "test"
}

variable "AZURE_RESOURCE_GROUP_NAME" {
  description = "Optional - the resource group for shared resources for the cluster.  Example: Azure VNET"
  default = "hashicluster"
}

variable "AZURE_DC_LOCATION" {
  default = "Canada Central"
}

variable "CONSUL_VMSS_NAME" {
  description = "Optional - the name of the Consul VMSS cluster.  Defaults to 'consul-servers'"
  default = "consul-servers"
}

variable "CONSUL_VMSS_RG" {
  description = "Optional - the resource group where the Consul Server Cluster will deployed into. Defaults to 'consul-servers'"
  default = "consul-servers"
}

variable "CONSUL_MASTER_TOKEN" {
  description = "Optional - The Consul Master (Management) ACL Token.  It will be computed and then seeded into the Server Configs if not supplied"
  default = ""
}



variable "CONSUL_SERVER_CLUSTER_VM_COUNT" {
  default = 3
}

variable "CONSUL_SERVER_CLUSTER_VM_SIZE" {
  default = "Standard_D2s_v3"
}

variable "HASHI_MANAGED_VM_IMAGE_NAME" {
  description = "Required - The customized image that will be used to deploy the cluster"
}

variable "ADMIN_NAME" {
  default = "hashiadmin"
}

variable "SSH_PUBLIC_KEY" {
  description = "Required - needed to log into server"
}

variable "CONSUL_ENCRYPT_KEY" {
  description = "Optional - the Consul Gossip Encryption Key."
  default = ""
}

variable "VAULT_KEY_SHARES" {
  default = "5"
}

variable "VAULT_KEY_THRESHOLD" {
  default = "3"
}

variable "VAULT_PGP_KEYS" {
  description = "PGP Key locations on the disk path, or keybase names.  Follows this: https://www.vaultproject.io/docs/concepts/pgp-gpg-keybase.html"
  default = "keybase:raykao,keybase:raykao,keybase:raykao,keybase:raykao,keybase:raykao"
}

variable "NOMAD_ENCRYPT_KEY" {
  description = "Optional - Nomad Encrytion Key for Server to Server Gossip.  One will be auto generated if not supplied."
  default = ""
}
