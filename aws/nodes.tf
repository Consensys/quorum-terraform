resource "aws_instance" "nodes" {
  for_each = merge(var.nodes_list,{for x in range(2,var.node_count+2) : x => "node-${tonumber(x)-2}"})
  ami = var.ubuntu_id
  instance_type = "${var.node_instance_type}"
  key_name = "${var.default_ssh_key}"
  subnet_id = each.key<2 ? "${module.vpc.public_subnets[each.key]}" : "${element(module.vpc.public_subnets, each.key % 3)}"
  vpc_security_group_ids = ["${module.ssh_security_group.security_group_id}", "${aws_security_group.eth_sg.id}"]
  iam_instance_profile = "${aws_iam_instance_profile.monitoring_profile.name}"
  associate_public_ip_address = true
  ebs_optimized = true
  root_block_device {
    volume_size = 40
  }
  tags = {
    #modified tags to get both ibft boot and rpc nodes
    Name = "besu-${var.vpc_name}-${each.value}"
  }

  connection {
    type = "ssh"
    user = "${var.login_user}"
    host = "${self.public_ip}"
    private_key = "${file(var.default_ssh_key_path)}"
  }

  provisioner "file" {
    source = "./files/append_auth_keys.sh"
    destination = "$HOME/append_auth_keys.sh"
  }

  provisioner "file" {
    source = "./files/besu"
    destination = "$HOME"
  }

  provisioner "file" {
    source = "./files/besu_ibft/besu.yml"
    destination = "$HOME/besu/besu.yml"
  }

  provisioner "file" {
    source = "./files/besu_ibft/ibft.json"
    destination = "$HOME/besu/ibft.json"
  }

  provisioner "file" {
    source = "./files/besu_ibft/${each.value}"
    destination = "$HOME/besu/node_db/"
  }

  # when the provisioner fires up, wait for the instance to signal its finished booting, before attempting to install packages, apt is locked until then
  provisioner "remote-exec" {
    inline = [
      "timeout 120 /bin/bash -c 'until stat /var/lib/cloud/instance/boot-finished 2>/dev/null; do echo waiting ...; sleep 5; done'",
      "sh $HOME/append_auth_keys.sh ${join(" ", formatlist("'%s'", var.user_ssh_public_keys))}",
      "sudo apt-get update && sudo apt-get install -y apparmor apt-transport-https ca-certificates curl build-essential openjdk-11-jdk python3 python3-setuptools python3-pip python3-dev python3-virtualenv python3-venv virtualenv",
      "sudo sh $HOME/besu/setup.sh '${var.besu_version}' '${var.besu_download_url}' 'aws_instance.nodes[${each.key}].private_ip'",
      "sleep 30",
    ]
  }
}

resource "aws_route53_record" "dns" {
  for_each = aws_instance.nodes
  zone_id = "${aws_route53_zone.private.zone_id}"
  // modfied name to give individual name to different nodes
  name    = "${each.value.tags.Name}.${var.vpc_name}.${var.region}"
  type    = "A"
  ttl     = "300"
  records = ["${each.value.private_ip}"]
}