module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_info["name"]
  cidr = var.vpc_info["cidr"]

  azs             = var.azs
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_vpn_gateway   = false
  enable_dns_hostnames = true # necessary for using private hozed zones and domains
  enable_dns_support   = true # "

  tags = {
    terraform = "true"
    vpc       = var.vpc_info["name"]
  }
}
