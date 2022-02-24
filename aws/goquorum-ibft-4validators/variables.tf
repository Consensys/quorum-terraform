variable "network_name" {
  default = "josh"
}

variable "region_details" {
  type = map(string)
  default = { 
    region = "ap-southeast-2"
    ssh_key = "pegasys-sydney"
    ssh_key_path = "~/.ssh/consensys/pegasys-sydney.pem"
    private_zone_id = "Z0786174HW19QSTZ4KXW"
    private_zone_name = "sydney.pegasys.tech"
  }
}

variable "vpc_details" {
  type = map(any)
  default = {
    vpc_id = ["vpc-00a3a16d98f58571d"]
    vpc_cidr = ["10.2.0.0/16"]
    default_sg = ["sg-0f63a55b2bc43cce9"]
    azs = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
    public_subnets = [ "subnet-0dd691562251c046d", "subnet-0b8f5d54f436835a2", "subnet-05c5829d52b97ded4" ]
    private_subnets = [ "subnet-0bf98f1c462a94d23", "subnet-0e7cd49e8782e9731", "subnet-077285a209dca7f74" ]
  }
}

variable "node_details" {
  type = map(string)
  default = {
    node_type = "rpcnode"     # validator, rpcnode
    node_count = 1
    provisioning_path = "../files/"
    genesis_provisioning_path = "./files/goquorum/"
    iam_profile = ""
  }
}


variable "goquorum_version" {
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
    project_name = "josh"
    project_group = "blockchain"
    team = "ops"
  }
}