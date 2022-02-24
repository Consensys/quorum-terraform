

####################################################
# monitoring 
####################################################
module "monitoring" {
  source = "../modules/monitoring"
  network_name = var.network_name
  region_details = var.region_details
  vpc_details = var.vpc_details
  node_details = {
    provisioning_path = "../files/monitoring"
    ami_id = var.amzn2_ami_id
    instance_type = "t3.micro"
  }
  tags = var.tags
}

# common role for the eth nodes to use
resource "aws_iam_role" "eth_nodes_role" {
  name               = "${var.network_name}_eth_nodes_role"
  path               = "/"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  inline_policy {
    name = "${var.network_name}_eth_nodes_ec2_tag_policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = [
            "ec2:Describe*",
            "ec2:DeleteTags",
            "ec2:CreateTags"
          ]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }
}

resource "aws_iam_instance_profile" "eth_nodes_profile" {
  name = "${var.network_name}_eth_nodes_profile"
  role = aws_iam_role.eth_nodes_role.name
}

####################################################
# GoQuorum validators
####################################################
module "goquorum_validators" {
  source = "../modules/goquorum_node"
  network_name = var.network_name
  region_details = var.region_details
  vpc_details = var.vpc_details
  ingress_ips = {
    discovery_cidrs = var.vpc_details["vpc_cidr"]
    rpc_cidrs = var.vpc_details["vpc_cidr"]
  }
  node_details = {
    node_type = "validator"
    node_count = 4
    provisioning_path = "../files/"
    genesis_provisioning_path = "./files/goquorum/"
    iam_profile = aws_iam_instance_profile.eth_nodes_profile.name
    ami_id = var.amzn2_ami_id
    instance_type = var.instance_type
    volume_size = var.instance_volume_size
  }
  tags = var.tags
}

####################################################
# GoQuorum rpcnodes
####################################################
module "goquorum_rpcnodes" {
  source = "../modules/goquorum_node"
  network_name = var.network_name
  region_details = var.region_details
  vpc_details = var.vpc_details
  ingress_ips = {
    discovery_cidrs = var.vpc_details["vpc_cidr"]
    rpc_cidrs = var.vpc_details["vpc_cidr"]
  }
  node_details = {
    node_type = "rpcnode"
    node_count = 2
    provisioning_path = "../files/"
    genesis_provisioning_path = "./files/goquorum/"
    iam_profile = aws_iam_instance_profile.eth_nodes_profile.name
    ami_id = var.amzn2_ami_id
    instance_type = var.instance_type
    volume_size = var.instance_volume_size
  }
  tags = var.tags
}

