#creating security group for eth_sg

resource "aws_security_group" "eth_sg" {
  name        = "${var.vpc_info["name"]}_eth_sg"
  description = "${var.vpc_info["name"]}_eth_sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 30303
    to_port     = 30303
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_info["cidr"]}"]
  }

  ingress {
    from_port   = 30303
    to_port     = 30303
    protocol    = "udp"
    cidr_blocks = ["${var.vpc_info["cidr"]}"]
  }

  ingress {
    from_port   = 8545
    to_port     = 8545
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_info["cidr"]}"]
  }

  ingress {
    from_port   = 8546
    to_port     = 8546
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_info["cidr"]}"]
  }

  ingress {
    from_port   = 8547
    to_port     = 8547
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_info["cidr"]}"]
  }

  ingress {
    from_port   = 9545
    to_port     = 9545
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_info["cidr"]}"]
  }

  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_info["cidr"]}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}