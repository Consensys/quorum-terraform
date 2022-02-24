 
# Terraform

This follows on from the main [README.md](../README.md) and has more info on Azure specific details and variables

The following setup will provision a new Resource Group, Vnet and several VMs. If you have an existing resource group or Vnet, please modify it to use your settings

Node keys, genesis file, config etc can be found in the `files/besu_ibft` folder. Please modify with as many nodes you would like to provision and increase the count in `variables.tf`

The monitoring box has ports 3000 (grafana) open to 0.0.0.0/0 and the credentials are admin/Password1. Please login and change this, we suggest using an OAuth mechanism like Google.

Each node has ports 8545, 8546, 8547 open and ready for comms. The vnet also has a private DNS zone enabled so instances come up with the form:
<node><idx>.<vnet-name>.<location>
where:
idx is the node count, vpc-name & region are vars you define in the varaibles.tf file.
For example if vnet=ibft4 & region=eastus you would get the following:
```bash
bootnode.ibft4.eastus
rpcnode.ibft4.eastus
node0.ibft4.eastus
.
.
```

| Name           | Default Value | Description                        |
| -------------- | ------------- | -----------------------------------|
| `subscription_id` | "" | Your Azure subscription ID |
| `location` | eastus | The Azure location you're deploying to |
| `vnet` | ibft4 | The name of the Vnet to create |
| `vnet_cidr` | "10.0.0.0/16" | The network CIDR block of the VNet |
| `subnet_names` | ["eastus-a", "eastus-b", "eastus-c"] | Names to refer to the subnets |
| `subnets` | ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"] | Subnet CIDR blocks |
| `login_user` | unset | The user to login in with via ssh  |
| `login_ssh_public_key` | "ssh-rsa AA...= username@example.com" | The public key used to identify the user when logging into the VM |
| `login_ssh_private_key_path` | "/home/username/.ssh/id_rsa" | Path of the user's private key on the local system |
| `besu_version` | 1.3.8 | Version of Besu to install and run. All available versions are listed on our Besu [solutions](https://pegasys.tech/solutions/hyperledger-besu/) page |
| `besu_download_url` | https://bintray.com/hyperledger-org/besu-repo/download_file?file_path=besu-{{ besu_version }}.tar.gz | The download tar.gz file used. You can use this if you need to retrieve besu from a custom location such as an internal repository. |
| `node_count` | 5 | The number of nodes to spin up including the validators. Note this does not include the bootnode, rpcnode or the monitoring instances |
| `light_instance_type` | t3.medium | The instance type to use for the monitoring VM|
| `node_instance_type` | t3.medium | The instance type to use for the nodes|


## Usage
1. Ensure you have account credentials setup and for the right account, eg: `az login`

2. Change directory to `ibft-4-validators`

3. Update variables.tf to suit your needs
eg: update node_count, besu_version or provide a besu_download_url link if using a build from circleci or your own custom servers or repos

4. 
```bash
terraform init && terraform validate && terraform apply
```

5. Wait for the nodes to start

6. Destroy the env with 
```bash
terraform destroy
```
