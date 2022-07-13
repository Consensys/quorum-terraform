
locals {
  resource_prefix = "${var.network_name}"
}

resource "aws_security_group" "monitoring_sg" {
  name        = "${local.resource_prefix}_monitoring_sg"
  description = "${local.resource_prefix}_monitoring_sg"
  vpc_id      = var.vpc_details["vpc_id"][0]

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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
    cidr_blocks = [ var.vpc_details["vpc_cidr"][0] ]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

data "aws_iam_policy_document" "monitoring_inline_policy" {
  statement {
    sid = "1"
    actions   = ["ec2:Describe"]
    resources = ["*"]
  }
  statement {
    actions   = ["elasticloadbalancing:Describe*"]
    resources = ["*"]
  }
  statement {
    actions   = ["autoscaling:Describe*"]
    resources = ["*"]
  }
  statement {
    actions   = ["cloudwatch:ListMetrics", "cloudwatch:GetMetricStatistics", "cloudwatch:Describe*" ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "monitoring_access_role" {
  name               = "${local.resource_prefix}_monitoring_access_role"
  path               = "/"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  inline_policy {
    name = "${local.resource_prefix}_monitoring_ec2_read_tags"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
            "Effect": "Allow",
            "Action": "ec2:Describe*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "elasticloadbalancing:Describe*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:ListMetrics",
                "cloudwatch:GetMetricStatistics",
                "cloudwatch:Describe*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "autoscaling:Describe*",
            "Resource": "*"
        }
      ]
    })
  }
}

resource "aws_iam_instance_profile" "monitoring_profile" {
  name = "${local.resource_prefix}_monitoring_profile"
  role = "${aws_iam_role.monitoring_access_role.name}"
}

resource "aws_instance" "monitoring" {
  ami = var.node_details["ami_id"]
  instance_type = var.node_details["instance_type"]
  iam_instance_profile = aws_iam_instance_profile.monitoring_profile.name
  key_name = var.region_details["ssh_key"]
  subnet_id = var.vpc_details["public_subnets"][0]
  vpc_security_group_ids = [ aws_security_group.monitoring_sg.id ]
  associate_public_ip_address = true
  ebs_optimized = true
  root_block_device {
    volume_size = 100
  }
  tags = {
    Name = "${local.resource_prefix}-monitoring"
    project_name = var.tags.project_name
    project_group = var.tags.project_group
    team = var.tags.team
  }

  connection {
    type = "ssh"
    user = ${var.ec2_user}
    host = "${self.public_ip}"
    private_key = "${file(pathexpand(var.region_details.ssh_key_path))}"
  }

  provisioner "file" {
    source = "${var.node_details["provisioning_path"]}"
    destination = "/home/${var.ec2_user}/monitoring"
  }


  # when the provisioner fires up, wait for the instance to signal its finished booting, before attempting to install packages, apt is locked until then
  provisioner "remote-exec" {
    inline = [
      "timeout 120 /bin/bash -c 'until stat /var/lib/cloud/instance/boot-finished 2>/dev/null; do echo waiting ...; sleep 5; done'",
      "sudo yum install -y ${var.amzn2_base_packages}",
      "sudo amazon-linux-extras install -y docker && sudo usermod -a -G docker ${var.ec2_user}",
      "sudo systemctl enable --now docker && sudo systemctl restart docker",
      "sudo curl -L https://github.com/docker/compose/releases/download/1.29.1/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
      "sudo sh $HOME/monitoring/setup.sh '${var.region_details["region"]}' '${local.resource_prefix}' ",
      "sleep 30",
    ]
  }

  lifecycle {
    ignore_changes = all
  }
}
