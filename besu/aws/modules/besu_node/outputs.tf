output "bootnode_ip" {
  value = var.bootnode_ip == "" ? aws_instance.nodes[0].private_ip : null
}