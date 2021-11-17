resource "aws_iam_role" "monitoring_access_role" {
  name               = "${var.vpc_name}_${var.region}_monitoring_access_role"
  path               = "/"
  assume_role_policy = "${file("./files/monitoring/iam/ec2AssumeRolePolicy.json")}"
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
  ami = var.ubuntu_id
  instance_type = "t3.micro"
  key_name = "${var.default_ssh_key}"
  subnet_id = "${module.vpc.public_subnets[0]}"
  # changed this_security_group_id to security_group_id
  vpc_security_group_ids = ["${module.ssh_security_group.security_group_id}", "${aws_security_group.monitoring_sg.id}"]
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
    source = "./files/append_auth_keys.sh"
    destination = "$HOME/append_auth_keys.sh"
  }

  provisioner "file" {
    source = "./files/monitoring"
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
