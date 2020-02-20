
output "vpc_id" {
  description = "VPC id"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr_block
}

output "azs" {
  description = "VPC AZs"
  value       = module.vpc.azs
}

output "public_subnets" {
  description = "VPC Public Subnets"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "VPC Private Subnets"
  value       = module.vpc.private_subnets
}

output "nat_public_ips" {
  description = "VPC NAT Gateway IP"
  value       = module.vpc.nat_public_ips
}

output "monitoring_ip" {
  description = "Monitoring IP"
  value = "${aws_instance.monitoring.public_ip}"
}

output "bootnode_ip" {
  description = "Besu bootnode IP"
  value = "${aws_instance.ibft_bootnode.public_ip}"
}

output "node_ip" {
  description = "Besu node IP"
  value = "${aws_instance.ibft_nodes.*.public_ip}"
}
