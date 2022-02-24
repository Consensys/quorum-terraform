output "bootnode_ip" {
  value = var.node_details["node_type"] == "bootnode" ? aws_instance.nodes[0].public_ip : null
}