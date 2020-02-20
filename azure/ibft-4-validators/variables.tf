
variable "subscription_id" {
  default = "abcdefgh...."
}

variable "vnet" {
  default = "ibft4"
}

variable "vnet_cidr" {
  default = "10.0.0.0/16"
}

variable "location" {
  default = "eastus"
}

variable "subnet_names" {
  type    = list(string)
  default = ["eastus-a", "eastus-b", "eastus-c"]
}

variable "subnets" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "login_user" {
  default = "username"
}

variable "login_ssh_public_key" {
  default = "ssh-rsa AA...= username@example.com"
}

variable "login_ssh_private_key_path" {
  default = "/home/username/.ssh/id_rsa"
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

# monitoring and caliper dont need beefier machines
variable "light_instance_type" {
  default = "Standard_B2s"
}

variable "node_instance_type" {
  default = "Standard_D2s_v3"
}
