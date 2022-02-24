variable "network_name" {
  default = "besu"
}

variable "region_details" {
  type = map(string)
  default = { 
    region = "ap-southeast-2"
    ssh_key = "my-ssh-key"
    ssh_key_path = "~/.ssh/my-ssh-key.pem"
    private_zone_id = "Z...."
    private_zone_name = "my.private-dns.zone"
  }
}

variable "vpc_details" {
  type = map(any)
  default = {
    vpc_id = ["vpc-0..."]
    vpc_cidr = ["10.0.0.0/16"]
    default_sg = ["sg-0..."]
    azs = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
    public_subnets = [ "subnet-0..", "subnet-0..", "subnet-0.." ]
    private_subnets = [ "subnet-0..", "subnet-0..", "subnet-0.." ]
  }
}

variable "node_details" {
  type = map(string)
  default = {
    node_type = "rpcnode"     # bootnode, validator, rpcnode
    node_count = 1
    provisioning_path = "../files/besu"
    genesis_provisioning_path = "./files/besu"
    iam_profile = ""
    ami_id = ""
  }
}

variable "besu_version" {
  default = "22.1.0"
}

variable "amzn2_ami_id" {
  default = "ami-0a4e637babb7b0a86"
}

variable "instance_type" {
  default = "t3.large"
}

variable "instance_volume_size" {
  default = "100"
}

variable "tags" {
  type = map(string)
  default = {
    project_name = "ibft2"
    project_group = "blockchain"
    team = "ops"
  }
}