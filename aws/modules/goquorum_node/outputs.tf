

output "goquorum_discovery_sg" {
  description = "goquorum_discovery_sg"
  value = "${aws_security_group.goquorum_discovery_sg}"
}

output "goquorum_rpc_sg" {
  description = "goquorum_rpc_sg"
  value = "${aws_security_group.goquorum_rpc_sg}"
}

output "goquorum_nodes" {
  description = "goquorum nodes"
  value = "${aws_instance.goquorum_nodes.*}"
}

output "private_ips" {
  description = "goquorum nodes ips"
  value = "${aws_instance.goquorum_nodes.*.private_ip}"
}

