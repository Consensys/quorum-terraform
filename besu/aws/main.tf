# bootnodes
###########################
module "bootnodes" {
  source          = "./modules/besu_node"
  region_details  = var.region_details
  vpc_info        = var.vpc_info
  vpc_id          = module.vpc.vpc_id
  bootnode_ip     = ""
  public_subnets  = module.vpc.public_subnets
  private_subnets = module.vpc.private_subnets
  node_details = {
    node_type         = "bootnode"
    node_count        = var.besu_bootnode_count
    provisioning_path = "./files/besu"
    ami_id            = var.node_details["ami_id"]
    iam_profile       = aws_iam_instance_profile.eth_nodes_profile.name
    instance_type     = var.node_details["instance_type"]
    volume_size       = var.node_details["volume_size"]
  }
}

# RPC nodes
module "rpcnodes" {
  source         = "./modules/besu_node"
  depends_on     = [module.bootnodes]
  region_details = var.region_details
  vpc_info       = var.vpc_info
  vpc_id         = module.vpc.vpc_id
  bootnode_ip    = module.bootnodes.bootnode_ip

  node_details = {
    node_type         = "rpcnode"
    node_count        = var.besu_rpcnode_count
    provisioning_path = "./files/besu/"
    ami_id            = var.node_details["ami_id"]
    iam_profile       = aws_iam_instance_profile.eth_nodes_profile.name
    instance_type     = var.node_details["instance_type"]
    volume_size       = var.node_details["volume_size"]
  }
}

# Validators
module "validators" {
  source         = "./modules/besu_node"
  depends_on     = [module.bootnodes, module.rpcnodes]
  region_details = var.region_details
  vpc_info       = var.vpc_info
  vpc_id         = module.vpc.vpc_id
  bootnode_ip    = module.bootnodes.bootnode_ip

  node_details = {
    node_type         = "validator"
    node_count        = var.besu_validatornode_count
    provisioning_path = "./files/besu/"
    ami_id            = var.node_details["ami_id"]
    iam_profile       = aws_iam_instance_profile.eth_nodes_profile.name
    instance_type     = var.node_details["instance_type"]
    volume_size       = var.node_details["volume_size"]
  }
}