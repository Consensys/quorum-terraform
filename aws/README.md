 
# Terraform

This follows on from the main [README.md](../README.md) and has more info on AWS specific details and variables

The deployment creates all instances in the public subnets because it requires ssh access to provision them with Besu. Where possible we suggest deploying this from an instance in AWS and setting the nodes to deploy into the private_subnets

Node keys, genesis file, config etc can be found in the `files/besu_ibft` folder 

The monitoring box has ports 3000 (grafana) open to 0.0.0.0/0 and the credentials are admin/Password1. Please login and change this, we suggest using an OAuth mechanism like Google.

Each node has ports 8545, 8546, 8547 open and ready for comms. Each node also has DNS enabled with the form:
<node>-<idx>.<vpc-name>.<region>
where:
idx is the node count, vpc-name & region are vars you define in the varaibles.tf file.
For example if vpcname=ibft4 & region=ap-southeast-2 you would get the following:
```bash
bootnode.ibft4.ap-southeast-2
rpcnode..ibft4.ap-southeast-2
node-0.ibft4.ap-southeast-2
.
.
node-n.ibft4.ap-southeast-2
```

| Name           | Default Value | Description                        |
| -------------- | ------------- | -----------------------------------|
| `region` | ap-southeast-2 | The AWS region you're deploying to |
| `azs` | ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"] |  The AWS AZ's you would like to use in that region |
| `vpc_name` | ibft4 | The name of the VPC to create |
| `vpc_cidr` | "10.0.0.0/16" | The network CIDR block of the VPC |
| `public_subnets` | ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"] | Path to install to  |
| `private_subnets` | ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"] | Path for default configuration |
| `login_user` | ubuntu | The AMI's default user name that is used to ssh in  |
| `default_ssh_key` | "default-aws-pem.pem" | The name of the ssh pem key in AWS |
| `default_ssh_key_path` | "/home/username/.ssh/default-aws-pem.pem" | Path of that key on your local system, used to provision the instance |
| `user_ssh_public_keys` | [] | Any custom ssh keys you would like to provision as well  |
| `besu_version` | 1.3.8 | Version of Besu to install and run. All available versions are listed on our Besu [solutions](https://pegasys.tech/solutions/hyperledger-besu/) page |
| `besu_download_url` | https://bintray.com/hyperledger-org/besu-repo/download_file?file_path=besu-{{ besu_version }}.tar.gz | The download tar.gz file used. You can use this if you need to retrieve besu from a custom location such as an internal repository. |
| `node_count` | 5 | The number of nodes to spin up including the validators. Note this does not include the bootnode, rpcnode or the monitoring instances |
| `node_instance_type` | t3.medium | The instance type to use |



## Usage

1. Change directory to `ibft-4-validaotrs`

2. Update variables.tf to suit your needs
eg: update node_count, besu_version or provide a besu_download_url link if using a build from circleci or your own custom servers or repos

3. 
```bash
terraform init && terraform validate && terraform apply
```

5. Wait for the nodes to start



6. Destroy the env with 
```bash
terraform destroy
```
