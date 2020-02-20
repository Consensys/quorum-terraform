 
# Terraform

The following repo has example reference implementations of private networks on AWS and Azure. This is intended to get developers and ops people familiar with how to run a private ethereum network and understand the concepts involved.

Provisiong Besu on all nodes in these examples uses our [Ansible Galaxy role](https://galaxy.ansible.com/pegasyseng/hyperledger_besu). This makes it easy to upgrade, perform maintenance etc.

### Production Network Guidelines:
| ⚠️ **Note**: After you have familiarised yourself with the examples in this repo, it is recommended that you design your network based on your needs and take our [recommendations](https://besu.hyperledger.org/en/stable/HowTo/Deploy/Cloud/) into account.|
| --- |

#### IBFT2 with 4 validators and n nodes, with monitoring via prometheus and grafana
You get the following per setup:
- monitoring node with prometheus, grafana with the Besu dashboard
- 4 validators (bootnode, node-0, node-1 and node-2)
- rpcnode
- n nodes 


The keys for the various nodes can be found under `ibft-4-validators/files/besu-ibft/` Please modify with as many nodes you would like to provision and increase the count in `variables.tf`

The monitoring instances are provisioned with prometheus and will automatically pull in metrics for any nodes deployed in their respective networks. Credentials are provisioned via an instance IAM role. 
Grafana credentials are admin/Password1 - please login and change this, we suggest using an OAuth mechanism like Google.

### Usage

1. Ensure you have cloud account credentials setup and for the right account, eg: ENV_VARS override ~/.aws/credentials, refer to the precedence [here](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html)

2. Install [terraform](https://learn.hashicorp.com/terraform/getting-started/install.html)

3. Enter the platform of choice and change directory to `ibft-4-validators`

4. Update variables.tf to suit your needs
eg: update node_count, besu_version or provide a besu_download_url link if using a build from circleci or your own custom servers or repos

```bash
terraform init && terraform validate && terraform apply
```

5. Wait for the nodes to start



6. Destroy the env with 
```bash
terraform destroy
```
