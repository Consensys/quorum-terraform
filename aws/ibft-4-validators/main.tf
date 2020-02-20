
provider "aws" {
  version = "~> 2.7"
  region = "${var.region}"
}

data "aws_ami" "ubuntu" {
 most_recent = true
 owners      = ["099720109477"] # canonical
 filter {
   name   = "name"
   values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
 }
}

resource "aws_security_group" "monitoring_sg" {
  name        = "${var.vpc_name}_monitoring_sg"
  description = "${var.vpc_name}_monitoring_sg"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "monitoring_access_role" {
  name               = "${var.vpc_name}_${var.region}_monitoring_access_role"
  path               = "/"
  assume_role_policy = "${file("../files/monitoring/iam/ec2AssumeRolePolicy.json")}"
}

resource "aws_iam_policy_attachment" "monitoring_role_policy_attachment" {
  name       = "${var.vpc_name}_${var.region}_monitoring_role_policy_attachment"
  roles      = ["${aws_iam_role.monitoring_access_role.name}"]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "monitoring_profile" {
  name = "${var.vpc_name}_${var.region}_monitoring_profile"
  role = "${aws_iam_role.monitoring_access_role.name}"
}

resource "aws_instance" "monitoring" {
  ami = "${data.aws_ami.ubuntu.id}"
  instance_type = "t3.micro"
  key_name = "${var.default_ssh_key}"
  subnet_id = "${module.vpc.public_subnets[0]}"
  vpc_security_group_ids = ["${module.ssh_security_group.this_security_group_id}", "${aws_security_group.monitoring_sg.id}"]
  iam_instance_profile = "${aws_iam_instance_profile.monitoring_profile.name}"
  associate_public_ip_address = true
  ebs_optimized = true
  root_block_device {
    volume_size = 40
  }
  tags = {
    Name = "${var.vpc_name}-monitoring"
  }

  connection {
    type = "ssh"
    user = "${var.login_user}"
    host = "${self.public_ip}"
    private_key = "${file(var.default_ssh_key_path)}"
  }

  provisioner "file" {
    source = "../files/append_auth_keys.sh"
    destination = "$HOME/append_auth_keys.sh"
  }

  provisioner "file" {
    source = "../files/monitoring"
    destination = "$HOME"
  }

  provisioner "remote-exec" {
    inline = [
      "timeout 120 /bin/bash -c 'until stat /var/lib/cloud/instance/boot-finished 2>/dev/null; do echo waiting ...; sleep 1; done'",
      "sh $HOME/append_auth_keys.sh ${join(" ", formatlist("'%s'", var.user_ssh_public_keys))}",
      "sudo apt-get update && sudo apt-get install -y apparmor apt-transport-https ca-certificates curl build-essential",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - ",
      "sudo sh -c 'echo \"deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable\" > /etc/apt/sources.list.d/docker.list'",
      "sudo apt-get update && sudo apt-get -y install docker-ce",
      "sudo usermod -aG docker $USER",
      "sudo curl -L https://github.com/docker/compose/releases/download/1.24.1/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
      "sudo sh $HOME/monitoring/setup.sh ${var.region} ${var.login_user} ${var.vpc_name} ",
      "sleep 30",
    ]
  }
}

resource "aws_route53_record" "monitoring_dns" {
  zone_id = "${aws_route53_zone.private.zone_id}"
  name    = "monitoring.${var.vpc_name}.${var.region}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.monitoring.private_ip}"]
}

resource "aws_security_group" "eth_sg" {
  name        = "${var.vpc_name}_eth_sg"
  description = "${var.vpc_name}_eth_sg"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress {
    from_port   = 30303
    to_port     = 30303
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  ingress {
    from_port   = 30303
    to_port     = 30303
    protocol    = "udp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  ingress {
    from_port   = 8545
    to_port     = 8545
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  ingress {
    from_port   = 8546
    to_port     = 8546
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  ingress {
    from_port   = 8547
    to_port     = 8547
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  ingress {
    from_port   = 9545
    to_port     = 9545
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ibft_bootnode" {
  ami = "${data.aws_ami.ubuntu.id}"
  instance_type = "${var.node_instance_type}"
  key_name = "${var.default_ssh_key}"
  subnet_id = "${module.vpc.public_subnets[0]}"
  vpc_security_group_ids = ["${module.ssh_security_group.this_security_group_id}", "${aws_security_group.eth_sg.id}"]
  iam_instance_profile = "${aws_iam_instance_profile.monitoring_profile.name}"
  associate_public_ip_address = true
  ebs_optimized = true
  root_block_device {
    volume_size = 40
  }
  tags = {
    Name = "besu-${var.vpc_name}-bootnode"
  }

  connection {
    type = "ssh"
    user = "${var.login_user}"
    host = "${self.public_ip}"
    private_key = "${file(var.default_ssh_key_path)}"
  }

  provisioner "file" {
    source = "../files/append_auth_keys.sh"
    destination = "$HOME/append_auth_keys.sh"
  }

  provisioner "file" {
    source = "../files/besu"
    destination = "$HOME"
  }

  provisioner "file" {
    source = "files/besu_ibft/besu.yml"
    destination = "$HOME/besu/besu.yml"
  }

  provisioner "file" {
    source = "files/besu_ibft/ibft.json"
    destination = "$HOME/besu/ibft.json"
  }

  provisioner "file" {
    source = "files/besu_ibft/bootnode"
    destination = "$HOME/besu/node_db/"
  }

  # when the provisioner fires up, wait for the instance to signal its finished booting, before attempting to install packages, apt is locked until then
  provisioner "remote-exec" {
    inline = [
      "timeout 120 /bin/bash -c 'until stat /var/lib/cloud/instance/boot-finished 2>/dev/null; do echo waiting ...; sleep 5; done'",
      "sh $HOME/append_auth_keys.sh ${join(" ", formatlist("'%s'", var.user_ssh_public_keys))}",
      "sudo apt-get update && sudo apt-get install -y apparmor apt-transport-https ca-certificates curl build-essential openjdk-11-jdk python3 python3-setuptools python3-pip python3-dev python3-virtualenv python3-venv virtualenv",
      "sudo sh $HOME/besu/setup.sh '${var.besu_version}' '${var.besu_download_url}' '${aws_instance.ibft_bootnode.private_ip}'",
      "sleep 30",
    ]
  }
}

resource "aws_route53_record" "bootnode_dns" {
  zone_id = "${aws_route53_zone.private.zone_id}"
  name    = "bootnode.${var.vpc_name}.${var.region}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.ibft_bootnode.private_ip}"]
}

resource "aws_instance" "ibft_rpcnode" {
  ami = "${data.aws_ami.ubuntu.id}"
  instance_type = "${var.node_instance_type}"
  key_name = "${var.default_ssh_key}"
  subnet_id = "${module.vpc.public_subnets[1]}"
  vpc_security_group_ids = ["${module.ssh_security_group.this_security_group_id}", "${aws_security_group.eth_sg.id}"]
  iam_instance_profile = "${aws_iam_instance_profile.monitoring_profile.name}"
  associate_public_ip_address = true
  ebs_optimized = true
  root_block_device {
    volume_size = 40
  }

  tags = {
    Name = "besu-${var.vpc_name}-rpcnode"
  }

  connection {
    type = "ssh"
    user = "${var.login_user}"
    host = "${self.public_ip}"
    private_key = "${file(var.default_ssh_key_path)}"
  }

  provisioner "file" {
    source = "../files/append_auth_keys.sh"
    destination = "$HOME/append_auth_keys.sh"
  }

  provisioner "file" {
    source = "../files/besu"
    destination = "$HOME"
  }

  provisioner "file" {
    source = "files/besu_ibft/besu.yml"
    destination = "$HOME/besu/besu.yml"
  }

  provisioner "file" {
    source = "files/besu_ibft/ibft.json"
    destination = "$HOME/besu/ibft.json"
  }

  provisioner "file" {
    source = "files/besu_ibft/rpcnode"
    destination = "$HOME/besu/node_db/"
  }

  # when the provisioner fires up, wait for the instance to signal its finished booting, before attempting to install packages, apt is locked until then
  provisioner "remote-exec" {
    inline = [
      "timeout 120 /bin/bash -c 'until stat /var/lib/cloud/instance/boot-finished 2>/dev/null; do echo waiting ...; sleep 5; done'",
      "sh $HOME/append_auth_keys.sh ${join(" ", formatlist("'%s'", var.user_ssh_public_keys))}",
      "sudo apt-get update && sudo apt-get install -y apparmor apt-transport-https ca-certificates curl build-essential openjdk-11-jdk python3 python3-setuptools python3-pip python3-dev python3-virtualenv python3-venv virtualenv",
      "sudo sh $HOME/besu/setup.sh '${var.besu_version}' '${var.besu_download_url}' '${aws_instance.ibft_bootnode.private_ip}'",
      "sleep 30",
    ]
  }
}

resource "aws_route53_record" "rpcnode_dns" {
  zone_id = "${aws_route53_zone.private.zone_id}"
  name    = "rpcnode.${var.vpc_name}.${var.region}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.ibft_rpcnode.private_ip}"]
}

resource "aws_instance" "ibft_nodes" {
  ami = "${data.aws_ami.ubuntu.id}"
  instance_type = "${var.node_instance_type}"
  key_name = "${var.default_ssh_key}"
  subnet_id = "${element(module.vpc.public_subnets, count.index % 3)}"
  vpc_security_group_ids = ["${module.ssh_security_group.this_security_group_id}", "${aws_security_group.eth_sg.id}"]
  iam_instance_profile = "${aws_iam_instance_profile.monitoring_profile.name}"
  associate_public_ip_address = true
  ebs_optimized = true
  root_block_device {
    volume_size = 40
  }
  count = "${var.node_count}"
  tags = {
    Name = "besu-${var.vpc_name}-${count.index}"
  }

  connection {
    type = "ssh"
    user = "${var.login_user}"
    host = "${self.public_ip}"
    private_key = "${file(var.default_ssh_key_path)}"
  }

  provisioner "file" {
    source = "../files/append_auth_keys.sh"
    destination = "$HOME/append_auth_keys.sh"
  }

  provisioner "file" {
    source = "../files/besu"
    destination = "$HOME"
  }

  provisioner "file" {
    source = "files/besu_ibft/besu.yml"
    destination = "$HOME/besu/besu.yml"
  }

  provisioner "file" {
    source = "files/besu_ibft/ibft.json"
    destination = "$HOME/besu/ibft.json"
  }

  provisioner "file" {
    source = "files/besu_ibft/node-${count.index}"
    destination = "$HOME/besu/node_db/"
  }

  # when the provisioner fires up, wait for the instance to signal its finished booting, before attempting to install packages, apt is locked until then
  provisioner "remote-exec" {
    inline = [
      "timeout 120 /bin/bash -c 'until stat /var/lib/cloud/instance/boot-finished 2>/dev/null; do echo waiting ...; sleep 5; done'",
      "sh $HOME/append_auth_keys.sh ${join(" ", formatlist("'%s'", var.user_ssh_public_keys))}",
      "sudo apt-get update && sudo apt-get install -y apparmor apt-transport-https ca-certificates curl build-essential openjdk-11-jdk python3 python3-setuptools python3-pip python3-dev python3-virtualenv python3-venv virtualenv",
      "sudo sh $HOME/besu/setup.sh '${var.besu_version}' '${var.besu_download_url}' '${aws_instance.ibft_bootnode.private_ip}'",
      "sleep 30",
    ]
  }
}

resource "aws_route53_record" "nodes_dns" {
  count = "${var.node_count}"
  zone_id = "${aws_route53_zone.private.zone_id}"
  name    = "node-${count.index}.${var.vpc_name}.${var.region}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.ibft_nodes[count.index].private_ip}"]
}
