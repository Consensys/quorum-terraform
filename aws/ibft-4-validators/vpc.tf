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

module "http_80_security_group" {
  source = "terraform-aws-modules/security-group/aws//modules/http-80"
  name = "${var.vpc_name}_http_sg"
  description = "${var.vpc_name}_http_sg"
  vpc_id = "${module.vpc.vpc_id}"
  ingress_cidr_blocks = ["0.0.0.0/0"]
}

module "https_443_security_group" {
  source = "terraform-aws-modules/security-group/aws//modules/https-443"
  name = "${var.vpc_name}_https_sg"
  description = "${var.vpc_name}_https_sg"
  vpc_id = "${module.vpc.vpc_id}"
  ingress_cidr_blocks = ["0.0.0.0/0"]
}

module "ssh_security_group" {
  source = "terraform-aws-modules/security-group/aws//modules/ssh"
  name = "${var.vpc_name}_ssh_sg"
  description = "${var.vpc_name}_ssh_sg"
  vpc_id = "${module.vpc.vpc_id}"
  ingress_cidr_blocks = ["0.0.0.0/0"]
}
