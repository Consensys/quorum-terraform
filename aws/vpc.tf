module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.vpc_name}"
  cidr = "${var.vpc_cidr}"

  azs             = "${var.azs}"
  public_subnets  = "${var.public_subnets}"
  private_subnets = "${var.private_subnets}"

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_vpn_gateway = false
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    terraform = "true"
    vpc = "${var.vpc_name}"
  }
}
resource "aws_route53_zone" "private" {
  name = "${var.vpc_name}.${var.region}"
  vpc {
    vpc_id = "${module.vpc.vpc_id}"
  }
}