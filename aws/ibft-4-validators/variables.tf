
variable "region" {
  default = "ap-southeast-2"
}

variable "azs" {
  type    = list(string)
  default = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
}

variable "vpc_name" {
  default = "ibft4"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "login_user" {
  default = "ubuntu"
}

# the name of the ssh key pair in aws
# this tells aws to provision instances with this keypair
variable "default_ssh_key" {
  default = "default-aws-pem.pem"
}

# the path to this key pair locally
# this is used by terrafrom to ssh in and run any provisioning steps
# NOTE/GOTCHA: on osx this generally goes along the lines '/Users/username/.....' and on linux it is '/home/username/...'
variable "default_ssh_key_path" {
  default = "/home/username/.ssh/default-aws-pem.pem"
}

variable "user_ssh_public_keys" {
  type = "list"
  default = []
}

# make sure the besu_version and download_url match in the number
# eg: 1.3.8 for version is used for anything that contains 1.3.8-rc.. or 1.3.8-snapshot.. etc
variable "besu_version" {
  default = "1.3.8"
}

variable "besu_download_url" {
  default = "https://bintray.com/hyperledger-org/besu-repo/download_file?file_path=besu-{{besu_version}}.tar.gz"
}

variable "node_count" {
  default = 5
}

variable "node_instance_type" {
  default = "t3.medium"
}
