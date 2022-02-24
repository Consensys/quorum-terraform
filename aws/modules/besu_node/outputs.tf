

output "besu_discovery_sg" {
  description = "besu_discovery_sg"
  value = "${aws_security_group.besu_discovery_sg}"
}

output "besu_rpc_sg" {
  description = "besu_rpc_sg"
  value = "${aws_security_group.besu_rpc_sg}"
}

output "besu_nodes" {
  description = "besu nodes"
  value = "${aws_instance.besu_nodes.*}"
}

output "private_ips" {
  description = "besu nodes ips"
  value = "${aws_instance.besu_nodes.*.private_ip}"
}

