login_user = "ubuntu" # make sure this set to ec2-user if using Amazon Linux or if running custom user
ami_id     = "ami-0fb653ca2d3203ac1" # this is the AWS ap-southeast-2 Ubuntu 20.04 LTS AMI
region_details = {
  region       = "ap-southeast-2"
  ssh_key      = "ap-southeast-2-dev"            # key name in AWS
  ssh_key_path = "./ssh/ap-southeast-2-dev.pem" # local private key for associated ssh key
}
besu_bootnode_count      = "1" # please note that only 1 bootnode is supported at this time
besu_rpcnode_count       = "1"
besu_validatornode_count = "4"
besu_version             = "21.10.5"