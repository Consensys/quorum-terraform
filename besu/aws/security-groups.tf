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