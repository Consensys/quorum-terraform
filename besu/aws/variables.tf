variable "login_user" {
  default = "ubuntu"
}

variable "azs" {
  type    = list(string)
  default = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
}

variable "vpc_info" {
  type = map(string)
  default = {
    name = "ibft4"
    cidr = "10.0.0.0/16"
  }
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

# map of region details
variable "region_details" {
  type = map(string)
  default = {
    region       = "ap-southeast-2"
    ssh_key      = "ap-southeast-2-dev"            # key name in AWS
    ssh_key_path = "./ssh/apt-southeast-2-dev.pem" # local private key for associated ssh key
    # private_zone_name = "terraform-besu.internal"
  }
}

# map of node details
variable "node_settings" {
  type = map(string)
  default = {
    node_type         = "rpcnode" # bootnode, validator, rpcnode
    node_count        = 1
    provisioning_path = "files/besu"
    ami_id            = "ami-0b7dcd6e6fd797935"
    instance_type     = "t3.xlarge"
    volume_size       = 500 # in GB
  }
}

variable "besu_bootnode_count" {
  default = "1" # please note that only 1 bootnode is supported at this time
}
variable "besu_rpcnode_count" {
  default = "1"
}
variable "besu_validatornode_count" {
  default = "4"
}

variable "user_ssh_public_keys" {
  type    = list(any)
  default = []
}

variable "besu_version" {
  default = "21.10.5"
}

variable "besu_download_url" {
  default = "https://bintray.com/hyperledger-org/besu-repo/download_file?file_path=besu-{{besu_version}}.tar.gz"
}