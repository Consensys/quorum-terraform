

locals {
  resource_prefix = "${var.network_name}-besu"
}

data "template_file" "provision_data_volume" {
  template = "${file("${path.module}/templates/dataVolume.tpl")}"
  vars = {
    besu_data_volume_size = "${var.node_details["volume_size"]}"
  }
}

resource "aws_security_group" "besu_discovery_sg" {
  name        = "${local.resource_prefix}-${var.node_details["node_type"]}-discovery-sg"
  description = "${local.resource_prefix}-${var.node_details["node_type"]}-discovery-sg"
  vpc_id      = var.vpc_details["vpc_id"][0]

  ingress {
    from_port   = 30303
    to_port     = 30303
    protocol    = "tcp"
    cidr_blocks = var.ingress_ips.discovery_cidrs
  }

  ingress {
    from_port   = 30303
    to_port     = 30303
    protocol    = "udp"
    cidr_blocks = var.ingress_ips.discovery_cidrs
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    self      = true
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = [ var.vpc_details["vpc_cidr"][0] ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_security_group" "besu_rpc_sg" {
  name        = "${local.resource_prefix}-${var.node_details["node_type"]}-rpc-sg"
  description = "${local.resource_prefix}-${var.node_details["node_type"]}-rpc-sg"
  vpc_id      = var.vpc_details["vpc_id"][0]

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8545
    to_port     = 8546
    protocol    = "tcp"
    cidr_blocks = concat(var.ingress_ips.rpc_cidrs, var.vpc_details["vpc_cidr"])
  }
}

resource "aws_instance" "besu_nodes" {
  ami = var.node_details["ami_id"]
  instance_type = var.node_details["instance_type"]
  iam_instance_profile = var.node_details["iam_profile"]
  key_name = var.region_details["ssh_key"]
  subnet_id = "${element(var.vpc_details["public_subnets"], count.index % length(var.vpc_details["public_subnets"]))}"
  vpc_security_group_ids = [ aws_security_group.besu_discovery_sg.id, aws_security_group.besu_rpc_sg.id  ]
  associate_public_ip_address = true
  ebs_optimized = true
  root_block_device {
    volume_size = 80
  }
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_size = var.node_details["volume_size"]
    volume_type = "gp2"
    delete_on_termination = true
    tags = {
      Name = "${local.resource_prefix}-${var.node_details["node_type"]}${count.index}-data"
      VPC = var.vpc_details["vpc_id"][0]
      ProjectName  = var.tags["project_name"]
      ProjectGroup = var.tags["project_group"]
      network  = var.network_name
      Team         = var.tags["team"]
    }
  }

  count = var.node_details["node_count"]
  tags = {
    Name = "${local.resource_prefix}-${var.node_details["node_type"]}${count.index}"
    VPC = var.vpc_details["vpc_id"][0]
    BesuVersion  = var.besu_version
    Team         = var.tags["team"]
  }

  connection {
    type = "ssh"
    user = "ec2-user"
    host = "${self.public_ip}"
    private_key = "${file(pathexpand(var.region_details.ssh_key_path))}"
  }

  provisioner "file" {
    content = "${data.template_file.provision_data_volume.rendered}"
    destination = "/home/ec2-user/provision_volume.sh"
  }

  # base ansible config
  provisioner "file" {
    source = "${var.node_details["provisioning_path"]}/besu/ansible"
    destination = "/home/ec2-user/besu"
  }

  # custom ansible config ie genesis static nodes, etc
  provisioner "file" {
    source = "${var.node_details["genesis_provisioning_path"]}"
    destination = "/home/ec2-user/besu"
  }
  # copy the keys
  provisioner "file" {
    source = "${var.node_details["provisioning_path"]}/nodes/${var.node_details["node_type"]}${count.index}"
    destination = "/home/ec2-user/besu/keys"
  }

  # when the provisioner fires up, wait for the instance to signal its finished booting, before attempting to install packages, apt is locked until then
  provisioner "remote-exec" {
    inline = [
      "timeout 120 /bin/bash -c 'until stat /var/lib/cloud/instance/boot-finished 2>/dev/null; do echo waiting ...; sleep 5; done'",
      "sudo yum install -y ${var.amzn2_base_packages}",
      "sudo sh $HOME/provision_volume.sh ",
      "sleep 120", # odd case of dns entries taking a while to create and when they take longer our ansible play fails - this halts the progression to allow the route53 entries to be created for the bootnodes
      "sudo sh $HOME/besu/setup.sh '${var.besu_version}' '${var.node_details["bootnode_ip"]}' '${var.node_details["node_type"]}' '${local.resource_prefix}' '${var.region_details["private_zone_name"]}' ",
      "sleep 30",
    ]
  }
  lifecycle {
    ignore_changes = all
  }
}

resource "aws_route53_record" "besu_nodes_dns" {
  count   = var.node_details["node_count"]
  zone_id = var.region_details["private_zone_id"]
  name    = "${local.resource_prefix}-${var.node_details["node_type"]}${count.index}.${var.region_details["private_zone_name"]}"
  type    = "A"
  ttl     = "300"
  records = [ aws_instance.besu_nodes[count.index].private_ip ]
}