# data "aws_ami" "ubuntu" {
#   most_recent = true
#   owners      = ["099720109477"] # canonical
#   filter {
#     name   = "name"
#     values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
#   }
# }

data "template_file" "provision_data_volume" {
  template = file("${path.module}/templates/dataVolume.tpl")
  vars = {
    besu_data_volume_size = var.node_details["volume_size"]
    login_user            = var.login_user
  }
}

module "ssh_security_group" {
  source              = "terraform-aws-modules/security-group/aws//modules/ssh"
  name                = "${var.vpc_info["name"]}_ssh_sg"
  description         = "${var.vpc_info["name"]}_ssh_sg"
  vpc_id              = var.vpc_id
  ingress_cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_instance" "nodes" {
  depends_on                  = [aws_eip.besu_node_eips]
  count                       = var.node_details["node_count"]
  ami                         = var.node_details["ami_id"]
  instance_type               = var.node_details["instance_type"]
  key_name                    = var.region_details["ssh_key"]
  subnet_id                   = element(var.public_subnets, count.index % length(var.public_subnets))
  vpc_security_group_ids      = [module.ssh_security_group.security_group_id, var.sg_attach]
  iam_instance_profile        = var.node_details["iam_profile"]
  associate_public_ip_address = true
  ebs_optimized               = true

  root_block_device {
    volume_size = 40
  }

  ebs_block_device {
    device_name           = "/dev/sdf"
    volume_size           = var.node_details["volume_size"]
    volume_type           = "gp3"
    delete_on_termination = var.delete_volumes_on_termination
    tags = {
      Name   = "${var.node_details["node_type"]}-${count.index}-data"
      VPC_id = var.vpc_id
    }
  }

  tags = {
    #modified tags to get both ibft boot and rpc nodes
    Name = "besu-${var.vpc_info["name"]}-${var.node_details["node_type"]}-${count.index}"
  }

  connection {
    type        = "ssh"
    user        = var.login_user
    host        = self.public_ip
    private_key = file(var.region_details["ssh_key_path"])
  }

  provisioner "file" {
    source      = "${path.module}/files/append_auth_keys.sh"
    destination = "/home/${var.login_user}/append_auth_keys.sh"
  }

  provisioner "file" {
    source      = "${path.module}/files/besu"
    destination = "/home/${var.login_user}"
  }

  provisioner "file" {
    source      = "${path.module}/files/besu_ibft/besu.yml"
    destination = "/home/${var.login_user}/besu/besu.yml"
  }

  provisioner "file" {
    source      = "${path.module}/files/besu_ibft/ibft.json"
    destination = "/home/${var.login_user}/besu/ibft.json"
  }

  provisioner "file" {
    source      = "${path.module}/files/besu_ibft/${var.node_details["node_type"]}-${count.index}/key"
    destination = "/home/${var.login_user}/besu/key"
  }

  provisioner "file" {
    content     = data.template_file.provision_data_volume.rendered
    destination = "/home/${var.login_user}/provision_volume.sh"
  }

  # when the provisioner fires up, wait for the instance to signal its finished booting, before attempting to install packages, apt is locked until then
  provisioner "remote-exec" {
    inline = [
      "timeout 120 /bin/bash -c 'until stat /var/lib/cloud/instance/boot-finished 2>/dev/null; do echo waiting ...; sleep 5; done'",
      "sh /home/${var.login_user}/append_auth_keys.sh ${join(" ", formatlist("'%s'", var.user_ssh_public_keys))}",
      "sudo apt update && sudo apt install -y apparmor apt-transport-https ca-certificates curl build-essential openjdk-11-jdk python3 python3-setuptools python3-pip python3-dev python3-virtualenv python3-venv virtualenv",
      "sudo /bin/bash /home/${var.login_user}/provision_volume.sh",
      "sudo /bin/bash /home/${var.login_user}/besu/setup.sh '${var.besu_version}' '${var.node_details["node_type"] == "bootnode" ? self.private_ip : var.bootnode_ip}' '${var.login_user}'",
      "sleep 15",
    ]
  }
}

# data "aws_route53_zone" "private_zone" {
#   name         = var.region_details["private_zone_name"]
#   private_zone = true
# }

# resource "aws_route53_record" "dns" {
#   allow_overwrite = true
#   count   = var.node_details["node_count"]
#   zone_id = data.aws_route53_zone.private_zone.zone_id
#   name    = "${var.node_details["node_type"]}-${count.index}.${data.aws_route53_zone.private_zone.name}"
#   type    = "A"
#   ttl     = "300"
#   records = [ aws_eip.besu_node_eips[count.index].public_ip ]
# } 

resource "aws_eip" "besu_node_eips" {
  vpc   = true
  count = var.node_details["node_count"]
  lifecycle {
    ignore_changes = all
  }
}

resource "aws_eip_association" "eip_bootnodes_associate" {
  depends_on    = [aws_instance.nodes, aws_eip.besu_node_eips]
  instance_id   = aws_instance.nodes[count.index].id
  allocation_id = aws_eip.besu_node_eips[count.index].id
  count         = var.node_details["node_count"]
}

