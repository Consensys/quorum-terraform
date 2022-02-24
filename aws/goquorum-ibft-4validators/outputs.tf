
output "besu_validator_ips" {
  description = "goquorum validators IP"
  value = "${module.goquorum_validators.private_ips}"
}

# output "rpcnode_ips" {
#   description = "goquorum rpcnode IP"
#   value = "${module.goquorum_rpcnodes.private_ips}"
# }