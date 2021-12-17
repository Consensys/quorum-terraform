variable "login_user" {
  default = "ubuntu"
}

variable "vpc_info" {
  type = map(string)
  default = {
    name = "ibft4"
    cidr = "10.0.0.0/16"
  }
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

variable "user_ssh_public_keys" {
  type    = list(any)
  default = []
}

variable "besu_version" {
  default = "21.10.3"
}
