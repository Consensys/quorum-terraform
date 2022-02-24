# module "http_80_security_group" {
#   source              = "terraform-aws-modules/security-group/aws//modules/http-80"
#   name                = "${var.vpc_name}_http_sg"
#   description         = "${var.vpc_name}_http_sg"
#   vpc_id              = module.vpc.vpc_id
#   ingress_cidr_blocks = ["0.0.0.0/0"]
# }

# module "https_443_security_group" {
#   source              = "terraform-aws-modules/security-group/aws//modules/https-443"
#   name                = "${var.vpc_name}_https_sg"
#   description         = "${var.vpc_name}_https_sg"
#   vpc_id              = module.vpc.vpc_id
#   ingress_cidr_blocks = ["0.0.0.0/0"]
# }

# module "ssh_security_group" {
#   source              = "terraform-aws-modules/security-group/aws//modules/ssh"
#   name                = "${var.vpc_name}_ssh_sg"
#   description         = "${var.vpc_name}_ssh_sg"
#   vpc_id              = module.vpc.vpc_id
#   ingress_cidr_blocks = ["0.0.0.0/0"]
# }

#creating security group for eth_sg

resource "aws_security_group" "eth_sg" {
  name        = "${var.vpc_info["name"]}_eth_sg"
  description = "${var.vpc_info["name"]}_eth_sg"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 30303
    to_port     = 30303
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_info["cidr"]}"]
  }

  ingress {
    from_port   = 30303
    to_port     = 30303
    protocol    = "udp"
    cidr_blocks = ["${var.vpc_info["cidr"]}"]
  }

  ingress {
    from_port   = 8545
    to_port     = 8545
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_info["cidr"]}"]
  }

  ingress {
    from_port   = 8546
    to_port     = 8546
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_info["cidr"]}"]
  }

  ingress {
    from_port   = 8547
    to_port     = 8547
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_info["cidr"]}"]
  }

  ingress {
    from_port   = 9545
    to_port     = 9545
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_info["cidr"]}"]
  }

  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_info["cidr"]}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}