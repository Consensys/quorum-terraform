output "bootnode_ips" {
  description = "Besu bootnode IP"
  value = "${module.besu_bootnodes.private_ips}"
}

output "besu_validator_ips" {
  description = "Besu validators IP"
  value = "${module.besu_validators.private_ips}"
}

output "rpcnode_ips" {
  description = "Besu rpcnode IP"
  value = "${module.besu_rpcnodes.private_ips}"
}