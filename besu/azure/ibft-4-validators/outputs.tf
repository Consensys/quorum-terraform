
output "network_id" {
  description = "network id"
  value       = module.network.vnet_id
}

output "network_cidr_block" {
  description = "network CIDR block"
  value       = module.network.vnet_address_space
}

output "subnets" {
  description = "network subnets"
  value       = module.network.vnet_subnets
}

output "monitoring_vm_fqdn" {
  value = azurerm_public_ip.monitoring_public_ip.fqdn
}

